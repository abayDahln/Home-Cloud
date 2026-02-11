# 🖥️ HomeCloud Server Manager

The **HomeCloud Server Manager** is a cross-platform desktop application built with **Flutter** that serves as the control center for your HomeCloud backend.

## 🚀 Overview
This application performs two critical roles:
1.  **GUI Manager**: Provides a user-friendly interface to start, stop, and monitor the storage server.
2.  **Go Backend Host**: Bundles and executes the performance-oriented Go backend that handles the actual file storage logic.

---

## ✨ Features
- **Server Control**: One-click Start/Stop/Restart for the backend server.
- **Real-time Monitoring**: Visual graphs for CPU, RAM, Disk, and Network usage.
- **Log Viewer**: Live stream of server logs for easy debugging.
- **Configuration**: Edit your server settings (Port, Storage Path, Auth Token) directly from the app.
- **Tray Support**: Runs quietly in the system tray with status notifications.

---

## 📂 Backend (Golang)
The actual server logic is located in the `backend/` directory.

- **Language**: Go 1.24+
- **API**: High-performance REST API.
- **System Stats**: Built with `gopsutil`.
- **File Watching**: Real-time updates via `fsnotify`.

### Manual Backend Setup (CLI)
If you wish to run the backend without the GUI:
```bash
cd backend
go run main.go
```

---

## 🛠️ Development & Build

### Prerequisites
- Flutter SDK
- Go 1.20+
- (Windows Only) Visual Studio with C++ desktop development.

### Running the App
```bash
flutter pub get
flutter run -d windows
```

### Building MSIX (Windows Installer)
This project is configured with the `msix` package for professional Windows deployment.
```bash
flutter pub run msix:create
```

---

## 🔒 Security
The Server Manager allows you to set an `AUTH_TOKEN`. Ensure this is kept secure, as it is required by the **HomeCloud Client App** to authenticate and access your files.

---

## 📄 License
This project is licensed under the MIT License.
