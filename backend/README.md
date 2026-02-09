# HomeCloud Backend Server

A lightweight, self-hosted cloud storage backend written in Go.

---

## 📋 Requirements

- **Go** version 1.20 or later ([Download Go](https://go.dev/dl/))
- Windows/Linux/MacOS

---

## ⚡ Quick Start (Development)

1. **Double-click `start.bat`** (Windows) 
   
   This will:
   - Check if Go is installed
   - Create a default `.env` file if missing
   - Create the `uploads` folder if missing
   - Start the server

2. **Open the HomeCloud app** and connect to `http://YOUR_PC_IP:8080`

---

## 🔧 Configuration

Edit the `.env` file to customize your server:

```env
# Server port (default: 8080)
PORT=8080

# Authentication password (CHANGE THIS!)
AUTH_TOKEN=your_secure_password

# Storage directory (where files are saved)
WATCH_DIR=./uploads

# Storage quota in GB (50-1000)
STORAGE_QUOTA_GB=100
```

> ⚠️ **IMPORTANT**: Always change the default `AUTH_TOKEN` before using in production!

---

## 📦 Building for Distribution

To create a standalone executable:

1. **Run `build.bat`** (Windows)
   
   This will compile the server into a single `HomeCloudServer.exe` file.

2. **Distribute these files:**
   - `HomeCloudServer.exe` - The server executable
   - `run.bat` - Script to start the server
   - `.env.example` - Example configuration (user should rename to `.env`)

---

## 🚀 Running the Compiled Server

1. Create a folder for your server (e.g., `C:\HomeCloud`)
2. Copy the following files into it:
   - `HomeCloudServer.exe`
   - `run.bat`
3. Create a `.env` file with your configuration (see above)
4. **Double-click `run.bat`** to start the server

---

## 📡 API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/login` | POST | Authenticate with password |
| `/list` | GET | List files in root directory |
| `/list/{path}` | GET | List files in subdirectory |
| `/upload?path=` | POST | Upload file to path |
| `/download/{path}` | GET | Download file |
| `/stream/{path}` | GET | Stream media file |
| `/rename` | POST | Rename file/folder |
| `/move` | POST | Move file/folder |
| `/delete?path=` | DELETE | Delete file/folder |
| `/mkdir` | POST | Create new folder |
| `/info` | GET | Get system info (CPU, RAM, Disk) |
| `/settings` | GET/POST | Get/Update server settings |

---

## 🔒 Security Notes

1. **Change the default password** in `.env`
2. Use behind a **reverse proxy** (Nginx/Caddy) with HTTPS for internet access
3. Consider using a **VPN** for remote access
4. **Never expose port 8080 directly** to the public internet

---

## 🛠️ Troubleshooting

### Server won't start
- Make sure port 8080 is not in use by another application
- Check if `.env` file exists and has valid configuration

### Can't connect from app
- Make sure your firewall allows port 8080
- Use your computer's local IP address (e.g., `192.168.x.x`), not `localhost`
- Check if the server is running (you should see "Server running at..." message)

### Files not uploading
- Check if `uploads` folder exists and has write permissions
- Verify storage quota is not exceeded

---

## 📁 Folder Structure

```
backend/
├── main.go              # Server source code
├── .env                 # Configuration file (git ignored)
├── .env.example         # Example configuration template
├── go.mod               # Go module file
├── go.sum               # Go dependencies
├── start.bat            # Start server (development)
├── build.bat            # Build executable
├── run.bat              # Run compiled executable
├── settings.bat         # Interactive settings editor
├── HOW_TO_USE.txt       # Usage guide (EN/ID)
├── README.md            # This file
└── uploads/             # File storage directory
    └── (your files)
```

---

## 📄 License

MIT License
