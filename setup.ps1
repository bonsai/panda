param(
    [string]$Fps = "15"
)

Write-Host "=== Panda Setup ===" -ForegroundColor Cyan

# ── sqlite3 チェック ──
$sqlite = Get-Command sqlite3 -ErrorAction SilentlyContinue
if (-not $sqlite) {
    Write-Host "sqlite3 not found. Downloading..." -ForegroundColor Yellow
    $url = "https://www.sqlite.org/2025/sqlite-tools-win-x64-3490100.zip"
    $zip = "$env:TEMP\sqlite.zip"
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri $url -OutFile $zip -UseBasicParsing
        Expand-Archive -Path $zip -DestinationPath "$env:TEMP\sqlite" -Force
        $dest = "$env:USERPROFILE\.local\bin"
        New-Item -ItemType Directory -Path $dest -Force | Out-Null
        Copy-Item "$env:TEMP\sqlite\sqlite3.exe" "$dest\sqlite3.exe"
        $env:Path += ";$dest"
        [Environment]::SetEnvironmentVariable("Path", [Environment]::GetEnvironmentVariable("Path","User") + ";$dest", "User")
        Write-Host "sqlite3 installed to $dest" -ForegroundColor Green
    } catch {
        Write-Host "Download failed: $_" -ForegroundColor Red
        Write-Host "Install sqlite3 manually from https://sqlite.org/download.html" -ForegroundColor Yellow
        exit 1
    }
} else {
    sqlite3 --version
    Write-Host "sqlite3 OK" -ForegroundColor Green
}

# ── DB 初期化 ──
$db = Join-Path $PSScriptRoot "panda.db"
if (Test-Path $db) {
    Write-Host "panda.db already exists. Remove it first to reinitialize." -ForegroundColor Yellow
} else {
    sqlite3 $db ".read $PSScriptRoot\schema.sql"
    Write-Host "panda.db created (15x15 board)" -ForegroundColor Green
}

# ── Play 関数 ──
function global:Place-Stone($x, $y) {
    sqlite3 (Join-Path $PSScriptRoot "panda.db") "INSERT INTO gomoku_place(x,y) VALUES($x,$y);"
}

function global:Show-Board {
    Clear-Host
    sqlite3 (Join-Path $PSScriptRoot "panda.db") -header -column "SELECT * FROM gomoku_state;" "SELECT * FROM gomoku_display;"
}

function global:Reset-Game {
    sqlite3 (Join-Path $PSScriptRoot "panda.db") "UPDATE gomoku_board SET stone='.', move_no=NULL; DELETE FROM gomoku_moves;"
    Write-Host "Game reset." -ForegroundColor Yellow
}

function global:Start-Demo {
    $delay = [math]::Round(1000 / $Fps)
    $moves = @((7,7), (8,8), (7,8), (8,9), (7,9), (8,10), (7,10), (8,11), (7,11))
    Clear-Host
    Write-Host "=== Panda Demo ($Fps fps) ===" -ForegroundColor Cyan
    Write-Host "Press Ctrl+C to stop`n" -ForegroundColor DarkGray
    Start-Sleep 1
    foreach ($m in $moves) {
        sqlite3 (Join-Path $PSScriptRoot "panda.db") "INSERT INTO gomoku_place(x,y) VALUES($($m[0]),$($m[1]));"
        Clear-Host
        sqlite3 (Join-Path $PSScriptRoot "panda.db") -header -column "SELECT * FROM gomoku_state;" "SELECT * FROM gomoku_display;"
        Start-Sleep -Milliseconds $delay
    }
    Write-Host "`nDemo complete!" -ForegroundColor Green
    sqlite3 (Join-Path $PSScriptRoot "panda.db") "SELECT * FROM gomoku_win;"
}

Write-Host "`nSetup complete. Available commands:" -ForegroundColor Cyan
Write-Host "  Show-Board          # Display board" -ForegroundColor White
Write-Host "  Place-Stone x y     # Place a stone" -ForegroundColor White
Write-Host "  Start-Demo          # Run demo animation (Black wins in 9 moves)" -ForegroundColor White
Write-Host "  Reset-Game          # Reset board" -ForegroundColor White
Write-Host "`nOr use sqlite3 directly:" -ForegroundColor DarkGray
Write-Host "  sqlite3 panda.db" -ForegroundColor DarkGray
