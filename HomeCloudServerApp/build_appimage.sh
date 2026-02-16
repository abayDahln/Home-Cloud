#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="${SCRIPT_DIR}/AppImage.AppDir"
BUILD_DIR="${SCRIPT_DIR}/build/linux/x64/release/bundle"
APPIMAGE_OUTPUT="${SCRIPT_DIR}/HomeCloudServerApp.AppImage"
APPIMAGETOOL="appimagetool"

echo "============================================"
echo "  Building HomeCloudServerApp AppImage"
echo "============================================"

# --- 1. Check if Flutter build exists ---
if [ ! -d "${BUILD_DIR}" ] || [ ! -f "${BUILD_DIR}/home_cloud_server" ]; then
    echo "[INFO] Flutter build not found. Running 'flutter build linux --release'..."
    cd "${SCRIPT_DIR}"
    flutter build linux --release
fi

# --- 2. Check appimagetool ---
if ! command -v appimagetool &> /dev/null; then
    echo "[INFO] appimagetool not found. Downloading (AppImageKit version)..."
    wget -q "https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage" -O /tmp/appimagetool
    chmod +x /tmp/appimagetool
    APPIMAGETOOL="/tmp/appimagetool"
    echo "[INFO] appimagetool downloaded to /tmp/appimagetool"
fi

# --- 3. Prepare AppDir ---
echo "[INFO] Preparing AppDir..."

# Clean and recreate necessary directories
rm -rf "${APP_DIR}/data" "${APP_DIR}/lib" "${APP_DIR}/server"
mkdir -p "${APP_DIR}/data"
mkdir -p "${APP_DIR}/lib"
mkdir -p "${APP_DIR}/server"

# Copy Flutter bundle contents
cp "${BUILD_DIR}/home_cloud_server" "${APP_DIR}/"
cp -r "${BUILD_DIR}/data/"* "${APP_DIR}/data/"
cp -r "${BUILD_DIR}/lib/"* "${APP_DIR}/lib/"

# --- 3b. Bundle dependencies ---
echo "[INFO] Bundling library dependencies..."

# Function to copy a library and its dependencies recursively
bundle_library_deps() {
    local lib_path="$1"
    local dest_dir="$2"
    local lib_name
    lib_name=$(basename "$lib_path")

    # Skip if already copied or if it's a system lib we don't want to bundle
    if [ -f "${dest_dir}/${lib_name}" ]; then
        return
    fi

    # Skip core system libraries that should NOT be bundled for AppImage compatibility
    # Bundling GTK/GDK/GLib/Cairo stack causes FL_IS_COMPOSITOR assertion crashes
    case "$lib_name" in
        # Core C runtime - must come from host
        linux-vdso.so*|ld-linux*|libc.so*|libm.so*|libdl.so*|librt.so*|libpthread.so*|libresolv.so*|libnsl.so*|libutil.so*)
            return ;;
        libstdc++.so*|libgcc_s.so*)
            return ;;
        # GTK/GDK rendering stack - MUST match host display server
        libgtk-3.so*|libgdk-3.so*|libgdk_pixbuf*.so*|libgail*.so*)
            return ;;
        # GLib/GIO/GObject - core GTK foundation
        libglib-2.0.so*|libgio-2.0.so*|libgobject-2.0.so*|libgmodule-2.0.so*|libgthread*.so*)
            return ;;
        # Cairo/Pango - rendering
        libcairo.so*|libcairo-gobject.so*|libpango-1.0.so*|libpangocairo*.so*|libpangoft2*.so*|libharfbuzz*.so*)
            return ;;
        # ATK accessibility
        libatk-1.0.so*|libatk-bridge*.so*|libatspi*.so*)
            return ;;
        # System services
        libdbus-1.so*|libsystemd.so*|libudev.so*)
            return ;;
        # Font rendering
        libfontconfig.so*|libfreetype.so*)
            return ;;
        # Wayland
        libwayland-client.so*|libwayland-cursor.so*|libwayland-egl.so*|libwayland-server.so*)
            return ;;
        # Core X11/xcb (but NOT extensions like libXpresent, libXrandr, etc.)
        libX11.so*|libXext.so*|libxcb.so*|libxcb-shm.so*|libxcb-render.so*)
            return ;;
        # OpenGL
        libGL.so*|libGLX.so*|libGLdispatch.so*|libEGL.so*|libgbm.so*|libdrm.so*|libvulkan.so*)
            return ;;
    esac

    if [ -f "$lib_path" ]; then
        cp -L "$lib_path" "${dest_dir}/" 2>/dev/null || true
        echo "  Bundled: $lib_name"

        # Recursively bundle dependencies
        ldd "$lib_path" 2>/dev/null | grep "=> /" | awk '{print $3}' | while read -r dep; do
            bundle_library_deps "$dep" "$dest_dir"
        done
    fi
}

# Bundle dependencies of the main binary
echo "[INFO] Bundling dependencies for home_cloud_server..."
ldd "${APP_DIR}/home_cloud_server" 2>/dev/null | grep "=> /" | awk '{print $3}' | while read -r dep; do
    bundle_library_deps "$dep" "${APP_DIR}/lib"
done

# Bundle dependencies for all Flutter plugins in lib/
echo "[INFO] Bundling dependencies for Flutter plugins..."
find "${APP_DIR}/lib" -name "*.so" | while read -r plugin; do
    echo "  Checking deps for plugin: $(basename "$plugin")"
    ldd "$plugin" 2>/dev/null | grep "=> /" | awk '{print $3}' | while read -r dep; do
        bundle_library_deps "$dep" "${APP_DIR}/lib"
    done
done

# Copy server backend files if they exist
if [ -d "${BUILD_DIR}/server" ]; then
    cp -r "${BUILD_DIR}/server/"* "${APP_DIR}/server/"
    echo "[INFO] Server backend files bundled."
elif [ -f "${SCRIPT_DIR}/backend/linux/server_linux_amd64" ]; then
    cp "${SCRIPT_DIR}/backend/linux/server_linux_amd64" "${APP_DIR}/server/server"
    echo "[INFO] server_linux_amd64 copied as server."
fi

# Bundle dependencies for the backend server binary (if it exists and is dynamic)
if [ -f "${APP_DIR}/server/server" ]; then
    echo "[INFO] Bundling dependencies for backend server..."
    # Check if it's a dynamic executable
    if ldd "${APP_DIR}/server/server" >/dev/null 2>&1; then
        ldd "${APP_DIR}/server/server" 2>/dev/null | grep "=> /" | awk '{print $3}' | while read -r dep; do
            bundle_library_deps "$dep" "${APP_DIR}/lib"
        done
    else
        echo "  Backend server appears to be static or not an ELF (script?), skipping ldd."
    fi
fi

# Copy cloudflared if available
if [ -f "${SCRIPT_DIR}/backend/linux/cloudflared" ] && [ ! -f "${APP_DIR}/server/cloudflared" ]; then
    cp "${SCRIPT_DIR}/backend/linux/cloudflared" "${APP_DIR}/server/cloudflared"
    echo "[INFO] cloudflared bundled."
fi

# Copy .env if available
if [ -f "${SCRIPT_DIR}/backend/.env.example" ] && [ ! -f "${APP_DIR}/server/.env" ]; then
    cp "${SCRIPT_DIR}/backend/.env.example" "${APP_DIR}/server/.env"
    echo "[INFO] .env config bundled."
fi

# Copy config.yml if available
if [ -f "${SCRIPT_DIR}/backend/config.yml" ] && [ ! -f "${APP_DIR}/server/config.yml" ]; then
    cp "${SCRIPT_DIR}/backend/config.yml" "${APP_DIR}/server/config.yml"
    echo "[INFO] config.yml bundled."
fi

# Copy icon if not already there
if [ ! -f "${APP_DIR}/app_logo_installer.png" ]; then
    if [ -f "${SCRIPT_DIR}/assets/icon/app_logo_installer.png" ]; then
        cp "${SCRIPT_DIR}/assets/icon/app_logo_installer.png" "${APP_DIR}/app_logo_installer.png"
    elif [ -f "${SCRIPT_DIR}/assets/icon/app_logo.png" ]; then
        cp "${SCRIPT_DIR}/assets/icon/app_logo.png" "${APP_DIR}/app_logo_installer.png"
    fi
fi

# Set permissions
chmod +x "${APP_DIR}/AppRun"
chmod +x "${APP_DIR}/home_cloud_server"
[ -f "${APP_DIR}/server/server" ] && chmod +x "${APP_DIR}/server/server"
[ -f "${APP_DIR}/server/cloudflared" ] && chmod +x "${APP_DIR}/server/cloudflared"

# --- 4. Build AppImage ---
echo "[INFO] Building AppImage..."
# Fix line endings (Windows/WSL compatibility)
find "${APP_DIR}" -name '*.desktop' -exec sed -i 's/\r$//' {} \;
sed -i 's/\r$//' "${APP_DIR}/AppRun"

ARCH=x86_64 "${APPIMAGETOOL}" --appimage-extract-and-run "${APP_DIR}" "${APPIMAGE_OUTPUT}"

echo ""
echo "============================================"
echo "  SUCCESS: ${APPIMAGE_OUTPUT}"
echo "  Size: $(du -h "${APPIMAGE_OUTPUT}" | cut -f1)"
echo "============================================"
