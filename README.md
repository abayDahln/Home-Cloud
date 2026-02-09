# ☁️ HomeCloud

**HomeCloud** is a premium, self-hosted cloud storage solution that gives you full control over your digital life. Designed as a modern alternative to Google Drive, it combines a powerful **Go (Golang)** backend with a sleek, responsive **Flutter** frontend to deliver a seamless experience across Mobile and Desktop.

---

## ✨ Key Features

### 📂 Smart File Management
- **Full Control**: Create folders, upload, download, move, rename, and delete files with ease.
- **Multi-Platform**: Access your files from Android, iOS, Windows, Linux, and MacOS.
- **Background Uploads**: Continue working while files upload reliably in the background.

### 🔍 Search & Organize
- **Instant Search**: Find any file instantly with real-time filtering.
- **Smart Sorting**: Sort by name, size, date, or type. Directories are always pinned to the top for easy navigation.
- **Multi-Select**: Efficiently manage files with bulk actions (delete, move, share).

### 🎬 Media Experience
- **Built-in Media Player**: Listen to music with a **visualizer** and play videos directly within the app.
- **Image Viewer**: High-quality image previews with zoom and pan support.
- **Document Support**: Preview PDF and Office documents on the fly.

### 🛡️ Backup & Sync
- **Auto Backup**: Automatically sync selected local folders from your device to your private cloud.
- **Real-time Sync**: Changes reflect instantly across all connected devices.

### 📊 System Monitoring
- **Server Dashboard**: View real-time **CPU**, **RAM**, **Disk**, and **Network** usage of your host machine.
- **Dynamic Graphs**: Live visualization of system performance history.

### 🎨 Premium Design
- **Modern UI**: A clean, glassmorphism-inspired interface with smooth animations (Flutter Animate).
- **Dark/Light Mode**: (Coming Soon) optimized for all environments.
- **Responsive**: Perfectly adapts from mobile screens to large desktop monitors.

---

## 🛠️ Technology Stack

### Frontend (Flutter)
- **State Management**: [Riverpod](https://riverpod.dev/) for robust and testable state management.
- **Networking**: [Dio](https://pub.dev/packages/dio) for handling API requests with retry interceptors.
- **Navigation**: [GoRouter](https://pub.dev/packages/go_router) for deep linking and flexible routing.
- **UI Libraries**: 
  - `flutter_animate` for effects.
  - `google_fonts` for typography.
  - `percent_indicator` for storage bars.
- **Native Integration**: 
  - `window_manager` & `tray_manager` for Desktop OS integration.
  - `flutter_foreground_task` for reliable background services on Android.
  - `permission_handler` for OS permissions.

### Backend (Golang)
- **Core**: Built with Go 1.24+ for high performance and low concurrency overhead.
- **System Stats**: [`gopsutil`](https://github.com/shirou/gopsutil) for cross-platform system monitoring.
- **File System**: [`fsnotify`](https://github.com/fsnotify/fsnotify) for watching file changes in real-time.
- **Config**: [`godotenv`](https://github.com/joho/godotenv) for environment variable management.

---

## 🚀 Installation & Setup

### 1. Backend Setup (The Server)
The backend runs on your host machine (Server/PC) to manage files and system stats.

1.  **Prerequisites**: Install [Go](https://go.dev/dl/) (v1.20+).
2.  Navigate to the backend directory:
    ```bash
    cd backend
    ```
3.  Install dependencies:
    ```bash
    go mod tidy
    ```
4.  Create a `.env` file in the `backend` folder:
    ```env
    PORT=8080
    AUTH_TOKEN=change_this_to_a_secure_token
    WATCH_DIR=./uploads
    STORAGE_QUOTA_GB=100
    ```
5.  Run the server:
    ```bash
    go run main.go
    ```
    *The server will start on `http://localhost:8080`.*

### 2. Frontend Setup (The App)
The client app connects to your backend.

1.  **Prerequisites**: Install [Flutter SDK](https://docs.flutter.dev/get-started/install).
2.  Install dependencies:
    ```bash
    flutter pub get
    ```
3.  **Run the App**:
    - **Desktop (Windows/Linux/Mac)**:
      ```bash
      flutter run -d windows
      ```
    - **Mobile (Android)**:
      Connect your device or start an emulator:
      ```bash
      flutter run -d android
      ```

### 3. Web Installer (Optional)
The project includes a separate web-based installer built with React/Vite.
1. Navigate to the installer directory:
   ```bash
   cd HomeCloudWebInstaller
   ```
2. Install dependencies & run:
   ```bash
   npm install
   npm run dev
   ```

---

## 📱 Building for Production

### Android (APK)
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Windows (EXE)
```bash
flutter build windows --release
# Output: build/windows/x64/runner/Release/
```
*Note: To create a single .exe installer, you can use tools like Inno Setup or MSIX.*

---

## 📸 Screenshots

*(Add screenshots of your application here: Login Screen, Home Dashboard, Music Player, Server Stats)*

---

## 🔒 Security Note
This project is intended for **personal use**. 
- Always change the default `AUTH_TOKEN`.
- If exposing to the internet, use a **Reverse Proxy** (Nginx/Caddy) with **HTTPS** (Let's Encrypt).
- Do not expose the raw HTTP port (8080) directly to the public internet.

---

## 📄 License
This project is open-source and available under the **MIT License**.
