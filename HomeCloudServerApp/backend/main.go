package main

import (
	"encoding/json"
	"fmt"
	"io"
	"log"
	"mime"
	"net/http"
	"net/url"
	"os"
	"path/filepath"
	"runtime"
	"strings"
	"sync"
	"time"

	"github.com/fsnotify/fsnotify"
	"github.com/joho/godotenv"
	"github.com/shirou/gopsutil/v3/cpu"
	"github.com/shirou/gopsutil/v3/disk"
	"github.com/shirou/gopsutil/v3/host"
	"github.com/shirou/gopsutil/v3/mem"
	"github.com/shirou/gopsutil/v3/net"
	"github.com/shirou/gopsutil/v3/process"
)

var (
	watchDir          = "./uploads"
	authToken         = "123"
	storageQuotaGB    = 50
	maxUploadFileSize = int64(1 << 30)
	serverPort        = "8080"
)

const (
	debounceDuration = 500 * time.Millisecond
)

var (
	eventCache = make(map[string]time.Time)
	mu         sync.RWMutex

	currentStats  SystemStats
	statsMu       sync.RWMutex
	cachedDirSize int64
	labelCache    = make(map[string]string)
	labelCacheMu  sync.RWMutex
)

type SystemStats struct {
	CPUUsage     []float64
	CPUInfos     []cpu.InfoStat
	ProcessCount int
	TotalThreads int
	NetDownload  float64
	NetUpload    float64
	MemTotal     uint64
	MemUsed      uint64
	MemAvailable uint64
	MemFree      uint64
	Disks        []map[string]interface{}
	LastUpdate   time.Time
}

func loadEnv() {
	if err := godotenv.Load(); err != nil {
		log.Println("Warning: .env file not found, using default values")
	}

	if val := os.Getenv("WATCH_DIR"); val != "" {
		watchDir = val
	}
	if val := os.Getenv("AUTH_TOKEN"); val != "" {
		authToken = val
	}
	if val := os.Getenv("PORT"); val != "" {
		serverPort = val
	}
	if val := os.Getenv("STORAGE_QUOTA_GB"); val != "" {
		if q, err := fmt.Sscanf(val, "%d", &storageQuotaGB); err == nil && q > 0 {
			if storageQuotaGB < 1 {
				storageQuotaGB = 1
			} else if storageQuotaGB > 1000 {
				storageQuotaGB = 1000
			}
		}
	}
	if val := os.Getenv("MAX_UPLOAD_SIZE"); val != "" {
		var size int64
		if _, err := fmt.Sscanf(val, "%d", &size); err == nil {
			maxUploadFileSize = size
		}
	}
}

func main() {
	loadEnv()
	os.MkdirAll(watchDir, os.ModePerm)
	go startWatcher()
	go statsWorker()

	http.HandleFunc("/login", loginHandler)

	http.Handle("/uploads/", http.StripPrefix("/uploads/", http.FileServer(http.Dir(watchDir))))
	http.HandleFunc("/upload", authMiddleware(uploadHandler))
	http.HandleFunc("/download/", authMiddleware(downloadHandler))
	http.HandleFunc("/stream/", authMiddleware(streamHandler))
	http.HandleFunc("/list", authMiddleware(listHandler))
	http.HandleFunc("/list/", authMiddleware(listHandler))
	http.HandleFunc("/rename", authMiddleware(renameHandler))
	http.HandleFunc("/move", authMiddleware(moveHandler))
	http.HandleFunc("/delete", authMiddleware(deleteHandler))
	http.HandleFunc("/mkdir", authMiddleware(mkdirHandler))
	http.HandleFunc("/info", authMiddleware(systemInfoHandler))
	http.HandleFunc("/settings", authMiddleware(settingsHandler))

	fmt.Printf("Server running at http://localhost:%s\n", serverPort)
	fmt.Printf("API Port: %s\n", serverPort)

	// Wrap everything with CORS middleware
	handler := corsMiddleware(http.DefaultServeMux)
	log.Fatal(http.ListenAndServe("0.0.0.0:"+serverPort, handler))
}

func streamHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method == "OPTIONS" {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "GET, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Range, Authorization, Content-Type")
		w.Header().Set("Access-Control-Max-Age", "86400")
		w.WriteHeader(http.StatusNoContent)
		return
	}

	relativePath := strings.TrimPrefix(r.URL.Path, "/stream/")

	decodedPath, err := url.QueryUnescape(relativePath)
	if err != nil {
		decodedPath = relativePath
	}
	cleanPath := filepath.Clean("/" + decodedPath)
	fullPath := filepath.Join(watchDir, cleanPath)

	absWatchDir, _ := filepath.Abs(watchDir)
	absTarget, _ := filepath.Abs(fullPath)

	if !strings.HasPrefix(absTarget, absWatchDir) {
		http.Error(w, "Access denied", http.StatusForbidden)
		return
	}

	fileInfo, err := os.Stat(fullPath)
	if os.IsNotExist(err) {
		log.Printf("Stream: File not found: %s", fullPath)
		http.NotFound(w, r)
		return
	}

	if fileInfo.IsDir() {
		http.Error(w, "Cannot stream a directory", http.StatusBadRequest)
		return
	}

	file, err := os.Open(fullPath)
	if err != nil {
		log.Printf("Stream: Failed to open file: %s - %v", fullPath, err)
		http.Error(w, "Failed to open file", http.StatusInternalServerError)
		return
	}
	defer file.Close()

	ext := strings.ToLower(filepath.Ext(fullPath))
	mimeType := mime.TypeByExtension(ext)
	if mimeType == "" {
		switch ext {
		case ".mp3":
			mimeType = "audio/mpeg"
		case ".wav":
			mimeType = "audio/wav"
		case ".mp4":
			mimeType = "video/mp4"
		default:
			mimeType = "application/octet-stream"
		}
	} else if ext == ".mp3" {
		mimeType = "audio/mpeg"
	}

	w.Header().Set("Content-Type", mimeType)
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Access-Control-Allow-Methods", "GET, OPTIONS")
	w.Header().Set("Access-Control-Allow-Headers", "Range, Authorization, Content-Type")
	w.Header().Set("Access-Control-Expose-Headers", "Content-Length, Content-Range, Accept-Ranges")
	w.Header().Set("Cache-Control", "public, max-age=3600")

	log.Printf("Serving stream: %s (Type: %s)", cleanPath, mimeType)
	http.ServeContent(w, r, fileInfo.Name(), fileInfo.ModTime(), file)
}

func getDiskLabel(p disk.PartitionStat) string {
	labelCacheMu.RLock()
	if label, ok := labelCache[p.Mountpoint]; ok {
		labelCacheMu.RUnlock()
		return label
	}
	labelCacheMu.RUnlock()

	var label string
	label = getOSDiskLabel(p)

	if label != "" {
		labelCacheMu.Lock()
		labelCache[p.Mountpoint] = label
		labelCacheMu.Unlock()
	}
	return label
}

func systemInfoHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != "GET" {
		http.Error(w, "use GET method", http.StatusMethodNotAllowed)
		return
	}

	statsMu.RLock()
	stats := currentStats
	statsMu.RUnlock()

	projectPath, _ := filepath.Abs(watchDir)
	hostStat, _ := host.Info()

	var disks []map[string]interface{}
	var projectDisk map[string]interface{}

	projectDiskID := ""
	if runtime.GOOS == "windows" {
		projectDiskID = strings.ToLower(filepath.VolumeName(projectPath))
	}

	for _, d := range stats.Disks {
		diskCopy := make(map[string]interface{})
		for k, v := range d {
			diskCopy[k] = v
		}

		isProjectDisk := false
		mountpoint, ok := d["mountpoint"].(string)
		if ok {
			if runtime.GOOS == "windows" {
				if strings.ToLower(filepath.VolumeName(mountpoint)) == projectDiskID {
					isProjectDisk = true
				}
			} else {
				if strings.HasPrefix(projectPath, mountpoint) {
					isProjectDisk = true
				}
			}
		}

		if isProjectDisk {
			diskCopy["is_project_disk"] = true
			mu.RLock()
			usedBytes := uint64(cachedDirSize)
			mu.RUnlock()
			freeQuota := uint64(storageQuotaGB) * 1024 * 1024 * 1024

			diskCopy["total"] = usedBytes + freeQuota
			diskCopy["used"] = usedBytes
			diskCopy["free"] = freeQuota
			diskCopy["path"] = projectPath
			diskCopy["quota_setting"] = storageQuotaGB
			projectDisk = diskCopy
		}
		disks = append(disks, diskCopy)
	}

	info := map[string]interface{}{
		"os": map[string]string{
			"go_version": runtime.Version(),
			"os":         runtime.GOOS,
			"arch":       runtime.GOARCH,
			"cpu_count":  fmt.Sprintf("%d", runtime.NumCPU()),
		},
		"sys": map[string]interface{}{
			"Hostname":   hostStat.Hostname,
			"OS":         hostStat.OS,
			"Platform":   hostStat.Platform,
			"KernelArch": runtime.GOARCH,
		},
		"cpu": stats.CPUInfos,
		"cpu_process": map[string]interface{}{
			"usage": stats.CPUUsage,
		},
		"process": map[string]interface{}{
			"count":   stats.ProcessCount,
			"threads": stats.TotalThreads,
		},
		"memory": map[string]interface{}{
			"total":     stats.MemTotal,
			"used":      stats.MemUsed,
			"available": stats.MemAvailable,
			"free":      stats.MemFree,
		},
		"disks": disks,
		"network": map[string]float64{
			"download_MBps": stats.NetDownload,
			"upload_MBps":   stats.NetUpload,
			"download_Mbps": stats.NetDownload * 8,
			"upload_Mbps":   stats.NetUpload * 8,
		},
		"project_disk": projectDisk,
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(info)
}

func statsWorker() {
	ticker := time.NewTicker(2 * time.Second)
	defer ticker.Stop()

	lastNetStat, _ := net.IOCounters(false)

	updateStats(&lastNetStat)

	for range ticker.C {
		updateStats(&lastNetStat)
	}
}

func updateStats(lastNetStat *[]net.IOCountersStat) {
	cpuPercent, _ := cpu.Percent(0, false)
	cpuInfos, _ := cpu.Info()

	processes, _ := process.Processes()
	processCount := len(processes)

	totalThreads := 0
	if runtime.GOOS != "windows" {
		for _, p := range processes {
			t, err := p.NumThreads()
			if err == nil {
				totalThreads += int(t)
			}
		}
	}

	currentNetStat, _ := net.IOCounters(false)
	var rx, tx uint64
	if len(currentNetStat) > 0 && len(*lastNetStat) > 0 {
		rx = currentNetStat[0].BytesRecv - (*lastNetStat)[0].BytesRecv
		tx = currentNetStat[0].BytesSent - (*lastNetStat)[0].BytesSent
	}
	*lastNetStat = currentNetStat

	downloadMBps := float64(rx) / 1024 / 1024 / 2.0
	uploadMBps := float64(tx) / 1024 / 1024 / 2.0

	vmStat, _ := mem.VirtualMemory()

	partitions, _ := disk.Partitions(false)
	var disks []map[string]interface{}
	for _, p := range partitions {
		if runtime.GOOS == "windows" {
			if strings.HasPrefix(p.Device, "A:") || strings.HasPrefix(p.Device, "B:") {
				continue
			}
		}

		usage, err := disk.Usage(p.Mountpoint)
		if err != nil {
			continue
		}

		label := getDiskLabel(p)
		disks = append(disks, map[string]interface{}{
			"device":     p.Device,
			"mountpoint": p.Mountpoint,
			"label":      label,
			"fstype":     p.Fstype,
			"total":      usage.Total,
			"used":       usage.Used,
			"free":       usage.Free,
			"real_total": usage.Total,
			"real_used":  usage.Used,
			"real_free":  usage.Free,
		})
	}

	statsMu.Lock()
	currentStats = SystemStats{
		CPUUsage:     cpuPercent,
		CPUInfos:     cpuInfos,
		ProcessCount: processCount,
		TotalThreads: totalThreads,
		NetDownload:  downloadMBps,
		NetUpload:    uploadMBps,
		MemTotal:     vmStat.Total,
		MemUsed:      vmStat.Used,
		MemAvailable: vmStat.Available,
		MemFree:      vmStat.Free,
		Disks:        disks,
		LastUpdate:   time.Now(),
	}
	statsMu.Unlock()
}

func loginHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != "POST" {
		http.Error(w, "use POST method", http.StatusMethodNotAllowed)
		return
	}

	type Req struct {
		Password string `json:"password"`
	}

	var req Req
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Bad request", http.StatusBadRequest)
		return
	}

	if req.Password != authToken {
		http.Error(w, "Incorrect Password", http.StatusUnauthorized)
		return
	}

	w.Write([]byte("Server connected"))
}

func corsMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, OPTIONS, DELETE, PUT, PATCH")
		w.Header().Set("Access-Control-Allow-Headers", "Authorization, Content-Type, Range, X-Requested-With")
		w.Header().Set("Access-Control-Expose-Headers", "Content-Length, Content-Range, Accept-Ranges")
		w.Header().Set("Access-Control-Max-Age", "86400")

		if r.Method == http.MethodOptions {
			w.WriteHeader(http.StatusNoContent)
			return
		}

		next.ServeHTTP(w, r)
	})
}

func authMiddleware(next http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		log.Printf("Incoming request: %s %s from %s agent %s", r.Method, r.URL.Path, r.RemoteAddr, r.UserAgent())

		auth := r.Header.Get("Authorization")
		token := r.URL.Query().Get("token")

		if (auth == "" || !strings.HasPrefix(auth, "Bearer ") || strings.TrimPrefix(auth, "Bearer ") != authToken) && token != authToken {
			log.Printf("Unauthorized [%s]: Path=%s Remote=%s tokenParam=%s", r.Method, r.URL.Path, r.RemoteAddr, token)
			http.Error(w, "Unauthorized", http.StatusUnauthorized)
			return
		}
		next(w, r)
	}
}

func uploadHandler(w http.ResponseWriter, r *http.Request) {
	log.Printf("Upload request received from %s", r.RemoteAddr)
	if r.Method != "POST" {
		http.Error(w, "use POST method", http.StatusMethodNotAllowed)
		return
	}

	err := r.ParseMultipartForm(maxUploadFileSize)
	if err != nil {
		log.Printf("Upload: ParseMultipartForm error: %v", err)
		http.Error(w, "File too large or corrupt", http.StatusBadRequest)
		return
	}

	file, handler, err := r.FormFile("file")
	if err != nil {
		log.Printf("Upload: FormFile error: %v", err)
		http.Error(w, "File not found", http.StatusBadRequest)
		return
	}
	defer file.Close()

	mu.RLock()
	usedBytes := uint64(cachedDirSize)
	mu.RUnlock()

	const hardLimit = 1000 * 1024 * 1024 * 1024

	if usedBytes+uint64(handler.Size) > hardLimit {
		log.Printf("Upload rejected: Absolute hard limit reached (1000GB)")
		http.Error(w, "HomeCloud project limited to maximum 1000 GB total", http.StatusInsufficientStorage)
		return
	}

	log.Printf("Uploading file: %s, Size: %d", handler.Filename, handler.Size)

	subPath := r.URL.Query().Get("path")

	cleanSubPath := filepath.Clean(subPath)
	if strings.HasPrefix(cleanSubPath, "..") {
		http.Error(w, "Invalid path", http.StatusBadRequest)
		return
	}

	safePath := filepath.Join(watchDir, cleanSubPath)

	err = os.MkdirAll(safePath, os.ModePerm)
	if err != nil {
		log.Printf("Upload: Failed to create directory: %v", err)
		http.Error(w, "Failed to create target directory", http.StatusInternalServerError)
		return
	}

	filePath := filepath.Join(safePath, handler.Filename)
	fileBase := handler.Filename
	fileExt := ""
	if dot := strings.LastIndex(fileBase, "."); dot != -1 {
		fileExt = fileBase[dot:]
		fileBase = fileBase[:dot]
	}

	counter := 1
	for {
		if _, err := os.Stat(filePath); os.IsNotExist(err) {
			break
		}
		filePath = filepath.Join(safePath, fmt.Sprintf("%s(%d)%s", fileBase, counter, fileExt))
		counter++
	}

	dst, err := os.Create(filePath)
	if err != nil {
		http.Error(w, "Failed to save file", http.StatusInternalServerError)
		return
	}
	defer dst.Close()

	_, err = io.Copy(dst, file)
	if err != nil {
		http.Error(w, "Failed to copy file content", http.StatusInternalServerError)
		return
	}

	w.Write([]byte("File uploaded successfully to " + filepath.ToSlash(filepath.Join(subPath, filepath.Base(filePath)))))
}

func downloadHandler(w http.ResponseWriter, r *http.Request) {
	relativePath := strings.TrimPrefix(r.URL.Path, "/download/")

	cleanPath := filepath.Clean(relativePath)
	if strings.HasPrefix(cleanPath, "..") {
		http.Error(w, "Invalid path", http.StatusBadRequest)
		return
	}

	fullPath := filepath.Join(watchDir, cleanPath)

	absWatchDir, _ := filepath.Abs(watchDir)
	absTarget, _ := filepath.Abs(fullPath)

	if !strings.HasPrefix(absTarget, absWatchDir) {
		http.Error(w, "Access denied", http.StatusForbidden)
		return
	}

	if _, err := os.Stat(fullPath); os.IsNotExist(err) {
		http.NotFound(w, r)
		return
	}

	w.Header().Set("Content-Disposition", "attachment; filename=\""+filepath.Base(fullPath)+"\"")
	http.ServeFile(w, r, fullPath)
}

func listHandler(w http.ResponseWriter, r *http.Request) {
	basePath := strings.TrimPrefix(r.URL.Path, "/list")
	basePath = strings.TrimPrefix(basePath, "/")

	cleanPath := filepath.Clean(basePath)
	if strings.Contains(cleanPath, "..") {
		http.Error(w, "Invalid path", http.StatusBadRequest)
		return
	}

	absPath := filepath.Join(watchDir, cleanPath)

	info, err := os.Stat(absPath)
	if err != nil {
		http.Error(w, "Not found", http.StatusNotFound)
		return
	}

	if !info.IsDir() {
		w.Header().Set("Content-Type", mime.TypeByExtension(filepath.Ext(absPath)))
		w.Header().Set("Cache-Control", "public, max-age=86400")
		http.ServeFile(w, r, absPath)
		return
	}

	type Item struct {
		Name     string    `json:"name"`
		Path     string    `json:"path"`
		FullPath string    `json:"full_path"`
		IsDir    bool      `json:"is_dir"`
		Size     int64     `json:"size"`
		ModTime  time.Time `json:"mod_time"`
	}

	entries, err := os.ReadDir(absPath)
	if err != nil {
		http.Error(w, "Failed to read directory", http.StatusInternalServerError)
		return
	}

	absWatchDir, _ := filepath.Abs(watchDir)
	var items []*Item

	for _, entry := range entries {
		entryRelPath := filepath.Join(cleanPath, entry.Name())
		entryRelPath = filepath.ToSlash(entryRelPath)

		entryAbsPath := filepath.Join(absWatchDir, filepath.FromSlash(entryRelPath))

		entryInfo, err := entry.Info()
		if err != nil {
			http.Error(w, "Failed to get file info", http.StatusInternalServerError)
			return
		}

		items = append(items, &Item{
			Name:     entry.Name(),
			Path:     entryRelPath,
			FullPath: entryAbsPath,
			IsDir:    entry.IsDir(),
			Size:     entryInfo.Size(),
			ModTime:  entryInfo.ModTime(),
		})
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(items)
}

func renameHandler(w http.ResponseWriter, r *http.Request) {
	type Req struct {
		OldPath string `json:"old"`
		NewPath string `json:"new"`
	}

	var req Req
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Bad request", http.StatusBadRequest)
		return
	}

	oldPath := filepath.Join(watchDir, filepath.Clean(req.OldPath))
	newPath := filepath.Join(watchDir, filepath.Clean(req.NewPath))

	if _, err := os.Stat(oldPath); os.IsNotExist(err) {
		http.Error(w, "Old path does not exist", http.StatusNotFound)
		return
	}

	if err := os.MkdirAll(filepath.Dir(newPath), 0755); err != nil {
		http.Error(w, "Failed to create target folder: "+err.Error(), http.StatusInternalServerError)
		return
	}

	if err := os.Rename(oldPath, newPath); err != nil {
		http.Error(w, "Failed to rename: "+err.Error(), http.StatusInternalServerError)
		return
	}

	fmt.Fprintf(w, "Rename successful from %s to %s", req.OldPath, req.NewPath)
}

func moveHandler(w http.ResponseWriter, r *http.Request) {
	type Req struct {
		Source string `json:"source"`
		Dest   string `json:"dest"`
	}
	var req Req
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Bad request", http.StatusBadRequest)
		return
	}
	src := filepath.Join(watchDir, filepath.Clean(req.Source))
	dst := filepath.Join(watchDir, filepath.Clean(req.Dest))

	if _, err := os.Stat(src); os.IsNotExist(err) {
		http.Error(w, "Source not found", http.StatusNotFound)
		return
	}

	fileBase := filepath.Base(dst)
	fileExt := ""
	if dot := strings.LastIndex(fileBase, "."); dot != -1 && !((filepath.Base(src) == fileBase) && (dot == 0)) {
		srcInfo, err := os.Stat(src)
		if err == nil && !srcInfo.IsDir() {
			fileExt = fileBase[dot:]
			fileBase = fileBase[:dot]
		}
	}

	counter := 1
	for {
		if _, err := os.Stat(dst); os.IsNotExist(err) {
			break
		}

		dir := filepath.Dir(dst)
		dst = filepath.Join(dir, fmt.Sprintf("%s(%d)%s", fileBase, counter, fileExt))
		counter++
	}

	if err := os.Rename(src, dst); err != nil {
		http.Error(w, "Failed to move: "+err.Error(), http.StatusInternalServerError)
		return
	}
	w.Write([]byte("File/folder moved successfully"))
}

func deleteHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != "DELETE" {
		http.Error(w, "Use DELETE method", http.StatusMethodNotAllowed)
		return
	}

	target := r.URL.Query().Get("path")
	if target == "" {
		log.Println("Delete: empty path")
		http.Error(w, "path parameter required", http.StatusBadRequest)
		return
	}

	cleanPath := filepath.Clean(target)
	if strings.HasPrefix(cleanPath, "..") {
		http.Error(w, "Invalid path", http.StatusBadRequest)
		return
	}
	fullPath := filepath.Join(watchDir, cleanPath)

	absWatchDir, _ := filepath.Abs(watchDir)
	absTarget, _ := filepath.Abs(fullPath)

	log.Println("Target:", target)
	log.Println("Full path:", fullPath)

	if !strings.HasPrefix(absTarget, absWatchDir) {
		log.Println("Delete: Path not in allowed directory")
		http.Error(w, "Access denied", http.StatusForbidden)
		return
	}

	if _, err := os.Stat(fullPath); os.IsNotExist(err) {
		log.Println("Delete: File or folder not found:", fullPath)
		http.Error(w, "File or folder not found", http.StatusNotFound)
		return
	}

	if err := os.RemoveAll(fullPath); err != nil {
		log.Println("Delete: Failed to delete:", err)
		http.Error(w, "Failed to delete file/folder", http.StatusInternalServerError)
		return
	}

	log.Println("Deleted successfully:", fullPath)
	w.Write([]byte("File/folder deleted successfully"))
}

func mkdirHandler(w http.ResponseWriter, r *http.Request) {
	type Req struct {
		Path string `json:"path"`
	}
	var req Req
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Bad request", http.StatusBadRequest)
		return
	}

	if req.Path == "" || strings.Contains(req.Path, "..") {
		http.Error(w, "Invalid path", http.StatusBadRequest)
		return
	}

	cleanPath := filepath.Clean(req.Path)
	if strings.HasPrefix(cleanPath, "..") {
		http.Error(w, "Invalid path", http.StatusBadRequest)
		return
	}

	targetPath := filepath.Join(watchDir, cleanPath)

	absTarget, _ := filepath.Abs(targetPath)
	absWatch, _ := filepath.Abs(watchDir)
	if !strings.HasPrefix(absTarget, absWatch) {
		http.Error(w, "Access denied", http.StatusForbidden)
		return
	}

	folderBase := cleanPath
	counter := 1
	for {
		if _, err := os.Stat(targetPath); os.IsNotExist(err) {
			break
		}
		targetPath = filepath.Join(watchDir, fmt.Sprintf("%s(%d)", folderBase, counter))
		counter++
	}

	if err := os.MkdirAll(targetPath, os.ModePerm); err != nil {
		http.Error(w, "Failed to create folder: "+err.Error(), http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusCreated)
	w.Write([]byte("Folder created: " + targetPath))
}

func startWatcher() {
	watcher, err := fsnotify.NewWatcher()
	if err != nil {
		log.Fatal(err)
	}
	defer watcher.Close()

	initialSize, _ := getDirSize(watchDir)
	mu.Lock()
	cachedDirSize = initialSize
	mu.Unlock()

	err = filepath.Walk(watchDir, func(path string, info os.FileInfo, err error) error {
		if info != nil && info.IsDir() {
			return watcher.Add(path)
		}
		return nil
	})

	if err != nil {
		log.Fatal(err)
	}

	for {
		select {
		case event, ok := <-watcher.Events:
			if !ok {
				return
			}
			handleEvent(event)

			if event.Op&fsnotify.Create == fsnotify.Create {
				info, err := os.Stat(event.Name)
				if err == nil {
					if info.IsDir() {
						watcher.Add(event.Name)
					} else {
						mu.Lock()
						cachedDirSize += info.Size()
						mu.Unlock()
					}
				}
			} else if event.Op&fsnotify.Remove == fsnotify.Remove || event.Op&fsnotify.Rename == fsnotify.Rename {
				go func() {
					newSize, _ := getDirSize(watchDir)
					mu.Lock()
					cachedDirSize = newSize
					mu.Unlock()
				}()
			}

		case err, ok := <-watcher.Errors:
			if !ok {
				return
			}
			log.Println("Watcher error:", err)
		}
	}
}

func handleEvent(event fsnotify.Event) {
	mu.Lock()
	defer mu.Unlock()

	now := time.Now()
	lastEvent, exists := eventCache[event.Name]
	if exists && now.Sub(lastEvent) < debounceDuration {
		return
	}
	eventCache[event.Name] = now

	switch {
	case event.Op&fsnotify.Create == fsnotify.Create:
		log.Println("New:", event.Name)
	case event.Op&fsnotify.Write == fsnotify.Write:
		log.Println("Modified:", event.Name)
	case event.Op&fsnotify.Remove == fsnotify.Remove:
		log.Println("Deleted:", event.Name)
	case event.Op&fsnotify.Rename == fsnotify.Rename:
		log.Println("Renamed:", event.Name)
	}
}

func getDirSize(path string) (int64, error) {
	var size int64
	err := filepath.WalkDir(path, func(_ string, d os.DirEntry, err error) error {
		if err != nil {
			return err
		}
		if !d.IsDir() {
			info, err := d.Info()
			if err == nil {
				size += info.Size()
			}
		}
		return nil
	})
	return size, err
}

func settingsHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method == "GET" {
		json.NewEncoder(w).Encode(map[string]interface{}{
			"storage_quota_gb": storageQuotaGB,
		})
		return
	}

	if r.Method == "POST" {
		type Settings struct {
			StorageQuotaGB int `json:"storage_quota_gb"`
		}
		var s Settings
		if err := json.NewDecoder(r.Body).Decode(&s); err != nil {
			http.Error(w, "Bad request", http.StatusBadRequest)
			return
		}

		if s.StorageQuotaGB < 1 || s.StorageQuotaGB > 1000 {
			http.Error(w, "Quota must be between 1 and 1000 GB", http.StatusBadRequest)
			return
		}

		mu.Lock()
		storageQuotaGB = s.StorageQuotaGB
		mu.Unlock()

		w.Write([]byte(fmt.Sprintf("Storage quota updated to %d GB (Restart server to reset from .env)", storageQuotaGB)))
		return
	}

	http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
}
