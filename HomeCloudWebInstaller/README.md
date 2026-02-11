# ☁️ HomeCloud Web Installer

Selamat datang di **HomeCloud Web Installer**, sebuah solusi web modern untuk mendistribusikan aplikasi HomeCloud ke berbagai platform. Proyek ini dibangun dengan fokus pada estetika premium, performa tinggi, dan pengalaman pengguna yang luar biasa.

## ✨ Fitur Utama

-   **Landing Page Dinamis**: Menampilkan keunggulan HomeCloud dengan desain modern dan bersih.
-   **Multi-Platform Download**: Halaman khusus untuk mengunduh installer Android, iOS, Windows, dan Linux.
-   **Responsive Design**: Dioptimalkan untuk semua ukuran layar (Desktop, Tablet, Mobile).
-   **Performa Cepat**: Dibangun dengan Vite dan React untuk waktu muat yang instan.
-   **Aesthetics Premium**: Menggunakan Tailwind CSS untuk styling yang konsisten dan elegan.

## 🛠️ Teknologi yang Digunakan

-   **Frontend**: [React 19](https://react.dev/)
-   **Build Tool**: [Vite](https://vitejs.dev/)
-   **Styling**: [Tailwind CSS](https://tailwindcss.com/)
-   **Routing**: [React Router 7](https://reactrouter.com/)

## ⬇️ Opsi Download

Terdapat dua bagian utama dalam ekosistem HomeCloud:

1.  **HomeCloud Client App**: Aplikasi untuk mengakses file Anda di berbagai platform (Android, Windows, Linux, iOS).
2.  **HomeCloud Backend Server**: Server yang harus diinstal di PC/Server Anda sebagai pusat penyimpanan data (berupa file `.zip`).

---

## 🛠️ Panduan Instalasi & Penggunaan

### 1. HomeCloud Backend Server (Pusat Data)
Backend ini berfungsi sebagai otak dari penyimpanan awan Anda.

**Persyaratan:**
-   [Go (Golang)](https://go.dev/dl/) (Versi 1.18 atau lebih baru)
-   Koneksi internet untuk instalasi awal

**Cara Menjalankan:**
1.  Unduh source code **HomeCloud Backend Server (.zip)**.
2.  Ekstrak file `.zip` tersebut ke folder pilihan Anda.
3.  Buka terminal atau Command Prompt di dalam folder tersebut.
4.  Jalankan server dengan perintah:
    ```bash
    go run main.go
    ```
    *Server akan berjalan di port default (biasanya 8080).*

---

### 2. HomeCloud Client App
Aplikasi yang digunakan oleh pengguna untuk mengunggah dan mengelola file.

**Cara Menjalankan:**
-   **Android**: Unduh file `.apk` dan instal di ponsel Anda.
-   **Windows**: Unduh file `.exe` dan jalankan installer.
-   **Linux**: Unduh file `.AppImage`, berikan izin eksekusi (`chmod +x`), dan jalankan.

---

## 🔗 Menghubungkan App ke Server

Agar aplikasi dapat mengakses penyimpanan Anda, ikuti langkah berikut:

1.  Pastikan Server Backend sudah menyala.
2.  Cari tahu **Alamat IP** komputer server Anda (misal: `192.168.1.15`).
3.  Buka **HomeCloud Client App**.
4.  Pada halaman awal, masukkan alamat server Anda (contoh: `http://192.168.1.15:5000`).
5.  Login dengan akun Anda, dan Anda sudah siap mengelola file!

---

## 🚀 Cara Menjalankan Proyek Installer (Web Ini)

Jika Anda ingin memodifikasi atau menjalankan website installer ini secara lokal:

1.  **Instal Dependensi**
    ```bash
    npm install
    ```
2.  **Jalankan Mode Pengembangan**
    ```bash
    npm run dev
    ```
3.  **Build untuk Produksi**
    ```bash
    npm run build
    ```

## 📁 Struktur Proyek

```text
HomeCloudWebInstaller/
├── public/          # Aset statis (ikon, gambar)
├── src/
│   ├── components/  # Komponen reusable (Navbar, Footer, dll)
│   ├── pages/       # Halaman utama (Landing, About, Download)
│   ├── App.jsx      # Konfigurasi routing utama
│   └── main.jsx     # Entry point aplikasi
├── tailwind.config.js # Konfigurasi Tailwind CSS
└── vite.config.js     # Konfigurasi Vite
```

---

Dibuat dengan ❤️ untuk komunitas **HomeCloud**.
