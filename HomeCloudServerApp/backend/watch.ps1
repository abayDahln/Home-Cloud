$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = "."
$watcher.Filter = "*.go"
$watcher.IncludeSubdirectories = $true
$watcher.EnableRaisingEvents = $true

$action = {
    $path = $Event.SourceEventArgs.FullPath
    Write-Host "File changed: $path" -ForegroundColor Yellow
    
    # Kill existing process if running
    $proc = Get-Process "server" -ErrorAction SilentlyContinue
    if ($proc) {
        Stop-Process -Id $proc.Id -Force
        Write-Host "Restarting server..." -ForegroundColor Cyan
    }

    # Build and run
    go build -o server.exe .
    if ($?) {
        Start-Process -FilePath ".\server.exe" -NoNewWindow
    } else {
        Write-Host "Build failed!" -ForegroundColor Red
    }
}

Register-ObjectEvent $watcher "Changed" -Action $action
Register-ObjectEvent $watcher "Created" -Action $action
Register-ObjectEvent $watcher "Renamed" -Action $action

Write-Host "Watching for changes..." -ForegroundColor Green

# Initial run
go build -o server.exe .
if ($?) {
    Start-Process -FilePath ".\server.exe" -NoNewWindow
}

# Keep script running
while ($true) { Start-Sleep -Seconds 1 }
