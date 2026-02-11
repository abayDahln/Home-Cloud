# ☁️ HomeCloud Monorepo

Welcome to the **HomeCloud** monorepo. This repository contains the entire ecosystem of HomeCloud, a premium self-hosted cloud storage solution designed for full privacy and control over your digital life.

## 📂 Project Structure

The project is divided into three main components:

| Component | Description | Tech Stack |
| :--- | :--- | :--- |
| **[HomeCloudApp](./HomeCloudApp)** | The primary client application for end-users. | Flutter (Android, iOS, Windows) |
| **[HomeCloudServerApp](./HomeCloudServerApp)** | The server manager GUI and the core Go backend. | Flutter + Go |
| **[HomeCloudWebInstaller](./HomeCloudWebInstaller)** | The landing page and download portal. | React + Vite + Tailwind |

---

## 🚀 How It Works

1.  **Deploy the Server**: Install and run the `HomeCloudServerApp` on your host machine (Server/PC). This app manages the **Go Backend** which handles file storage, indexing, and system monitoring.
2.  **Access the Files**: Use the `HomeCloudApp` (Mobile or Desktop) to connect to your server's IP address.
3.  **Manage & Sync**: Upload, download, and sync your files with full privacy.

---

## 🛠️ Quick Start (Development)

### Prerequisites
- **Flutter SDK**: v3.2.0+
- **Go**: v1.20+
- **Node.js**: v18+ (for the Web Installer)

### Running the Components

#### 1. Server & Backend
```bash
cd HomeCloudServerApp
flutter run -d windows # To run the Manager GUI
# The Go backend is located in HomeCloudServerApp/backend
```

#### 2. Mobile/Desktop Client
```bash
cd HomeCloudApp
flutter run
```

#### 3. Web Installer
```bash
cd HomeCloudWebInstaller
npm install
npm run dev
```

---

## 🛡️ Security & Privacy
HomeCloud is built with privacy-first principles. Your data never leaves your hardware unless you access it remotely. For production deployments, it is recommended to use a reverse proxy (like Nginx or Caddy) with SSL/TLS.

---

## 📄 License
This project is licensed under the MIT License - see the individual apps for details.
