# Home Screen Implementation

## Overview
Home screen telah didesain ulang sesuai dengan mockup design, dengan fitur-fitur modern seperti Google Drive dan informasi sistem real-time.

## Fitur Utama

### 1. **Storage Info Card**
- Menampilkan informasi penyimpanan server di bagian atas
- Menunjukkan used space vs total space dengan progress bar
- **Clickable** - Klik card untuk membuka System Info Dialog
- Data diambil dari project disk (disk tempat server berjalan)
- Update real-time setiap 2 detik

### 2. **File/Folder Cards (Google Drive Style)**
- Desain card yang clean dan modern
- Icon yang berbeda untuk setiap jenis file:
  - Folder: Blue folder icon
  - PDF: PDF icon
  - Images: Image icon
  - Videos: Video icon
  - Documents: Document icon
  - Archives: Zip icon
  - Default: Generic file icon
- Menampilkan ukuran file untuk non-folder
- Chevron right indicator untuk navigasi
- **Tap** untuk membuka folder atau file
- **Long Press** untuk menampilkan menu opsi

### 3. **Long Press Menu (Bottom Sheet)**
Saat user long-press pada file/folder, muncul bottom sheet dengan opsi:
- **Rename** - Mengubah nama file/folder
- **Move** - Memindahkan file/folder ke lokasi lain
- **Delete** - Menghapus file/folder (dengan konfirmasi)
- **Details** - Menampilkan informasi detail file (hanya untuk file)

### 4. **Pull to Refresh**
- **Swipe down** untuk refresh data
- Menggantikan tombol refresh yang lama
- Refresh file list dan system info secara bersamaan
- Smooth animation

### 5. **Real-time Updates**
- File list update otomatis setiap 3 detik
- System info update otomatis setiap 2 detik
- Menggunakan `StreamProvider` untuk polling
- Tidak ada flickering saat update

### 6. **System Info Dialog**
Dialog yang menampilkan informasi lengkap tentang server dengan 4 tabs:

#### **Processor Tab**
- Nama CPU dan model
- Jumlah cores
- Base speed (GHz)
- CPU utilization (%)
- Progress bar utilization
- Jumlah processes dan threads

#### **Memory Tab**
- Memory usage percentage
- Progress bar dengan legend (used/free)
- Total memory
- Used memory
- Available memory
- Free memory

#### **Storage Tab**
- List semua disk/partitions
- Badge "Server" untuk project disk
- Usage percentage per disk
- Progress bar per disk
- Used vs Free space
- Disk label dan mountpoint

#### **Network Tab**
- Download speed (MB/s dan Mbps)
- Upload speed (MB/s dan Mbps)
- Icon yang berbeda untuk download (green) dan upload (blue)
- Real-time update setiap 2 detik

### 7. **Navigation**
- Breadcrumb menampilkan nama folder saat ini
- Back button untuk navigasi ke parent folder
- Tap folder untuk masuk ke subfolder
- Root indicator saat di folder utama

### 8. **Floating Action Buttons**
- **Mini FAB** (atas) - Create new folder
- **Main FAB** (bawah) - Upload file
- Warna yang konsisten dengan tema

### 9. **Empty State**
- Icon folder terbuka
- Text "Empty folder"
- Centered layout

### 10. **Error Handling**
- Error state dengan icon dan pesan
- Graceful handling untuk network errors
- Tidak crash saat polling error

## File Operations

### Upload File
1. Klik FAB utama
2. Pilih file dari file picker
3. File diupload ke current path
4. Snackbar notification untuk status
5. Auto-refresh file list setelah upload

### Create Folder
1. Klik mini FAB
2. Input nama folder di dialog
3. Folder dibuat di current path
4. Auto-refresh file list setelah create

### Rename
1. Long press file/folder
2. Pilih "Rename"
3. Input nama baru di dialog
4. Konfirmasi untuk rename
5. Auto-refresh file list

### Move
1. Long press file/folder
2. Pilih "Move"
3. Input destination path
4. Konfirmasi untuk move
5. Auto-refresh file list

### Delete
1. Long press file/folder
2. Pilih "Delete"
3. Konfirmasi di dialog
4. File/folder dihapus
5. Auto-refresh file list

## UI/UX Improvements

### Design
- Clean, modern interface
- Consistent spacing dan padding
- Rounded corners untuk semua cards
- Shadow untuk depth
- Color scheme yang konsisten dengan AppColors

### Interactions
- Smooth animations
- Haptic feedback (long press)
- Loading states
- Success/error feedback via SnackBar
- Modal dialogs untuk confirmations

### Responsiveness
- Pull to refresh gesture
- Smooth scrolling
- No janky animations
- Efficient polling (tidak membebani UI)

## Technical Implementation

### State Management
- **Riverpod** untuk state management
- **StreamProvider** untuk real-time updates
- **StateNotifier** untuk file operations
- Auto-dispose untuk memory efficiency

### Data Flow
```
1. User opens app
2. systemInfoProvider starts polling /info endpoint (2s interval)
3. fileListProvider starts polling /list endpoint (3s interval)
4. UI updates automatically when data changes
5. User interactions trigger API calls
6. Success/error feedback via SnackBar
7. Auto-refresh after operations
```

### API Integration
- **GET /info** - System information
- **GET /list** atau **GET /list/{path}** - File listing
- **POST /upload** - Upload file
- **POST /mkdir** - Create folder
- **POST /rename** - Rename file/folder
- **POST /move** - Move file/folder
- **DELETE /delete** - Delete file/folder

### Models
- **SystemInfo** - Complete system information model
- **FileItem** - File/folder item model
- **AuthState** - Authentication state

### Providers
- **systemInfoProvider** - Real-time system info
- **fileListProvider** - Real-time file list
- **fileOpsProvider** - File operations
- **currentPathProvider** - Current directory path
- **authProvider** - Authentication state

## Performance Optimizations

1. **Auto-dispose providers** - Memory efficient
2. **Polling with error handling** - Tidak crash saat network error
3. **Efficient rebuilds** - Hanya rebuild widget yang berubah
4. **Lazy loading** - Data dimuat saat dibutuhkan
5. **Debouncing** - Mencegah multiple rapid requests

## Future Enhancements

1. **File Preview** - Preview image/video/PDF
2. **Bulk Operations** - Select multiple files
3. **Search** - Search files by name
4. **Sort & Filter** - Sort by name, size, date
5. **Upload Progress** - Show upload progress bar
6. **Download** - Download files to local device
7. **Favorites** - Mark files as favorites
8. **Recent Files** - Quick access to recent files
9. **Breadcrumb Navigation** - Click path segments
10. **Grid View** - Toggle between list and grid view

## Screenshots Reference

Implementasi mengikuti design mockups:
- `home_layout_tab_folder_root.png` - Main layout dengan storage info
- `home_layout_tab_info_subtab_processor.png` - Processor tab
- `home_layout_tab_info_subtab_storage.png` - Storage tab
- `home_layout_tab_info_subtab_memory.png` - Memory tab
- `home_layout_tab_info_subtab_network.png` - Network tab
