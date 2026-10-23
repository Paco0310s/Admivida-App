# =============================================================================
#  Genera el APK de Admivida para Android + el manifiesto de actualizacion
#
#  Uso (desde la raiz del proyecto):
#    .\scripts\build_android_apk.ps1
#    .\scripts\build_android_apk.ps1 -Notes "Correcciones y nueva funcion"
#    .\scripts\build_android_apk.ps1 -Mandatory -Notes "Actualizacion critica"
#
#  Resultado en build\installer\ :
#    - Admivida.apk           -> subir a MinIO: admivida-bucket/releases/Admivida.apk
#    - latest-android.json    -> subir a MinIO: admivida-bucket/releases/latest-android.json
#
#  La version se toma de AppConfig.appVersionCode / appVersionName.
# =============================================================================
param(
    [switch]$Mandatory,
    [string]$Notes = "",
    [switch]$SkipFlutterBuild
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

# --- 1. Leer version desde AppConfig ---------------------------------------
$configPath = Join-Path $root 'lib\common\constants\app_config.dart'
$config = Get-Content $configPath -Raw
$versionCode = [regex]::Match($config, 'appVersionCode\s*=\s*(\d+)').Groups[1].Value
$versionNameFull = [regex]::Match($config, "appVersionName\s*=\s*'([^']+)'").Groups[1].Value
$versionName = [regex]::Match($versionNameFull, '\d+\.\d+\.\d+').Value

if (-not $versionCode -or -not $versionName) {
    throw "No se pudo leer appVersionCode / appVersionName de $configPath"
}
Write-Host "==> Version: $versionNameFull (code $versionCode)" -ForegroundColor Cyan

# --- 2. Compilar Flutter APK en Release (completo / universal) -------------
$outDir = Join-Path $root 'build\installer'
if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir -Force | Out-Null }

$builtApk = Join-Path $root 'build\app\outputs\flutter-apk\app-release.apk'

if (-not $SkipFlutterBuild) {
    Write-Host "==> flutter build apk --release" -ForegroundColor Cyan
    flutter build apk --release --build-name=$versionName --build-number=$versionCode
    if ($LASTEXITCODE -ne 0) { throw "Fallo flutter build apk" }
}

if (-not (Test-Path $builtApk)) {
    throw "No se encontro el archivo compilado en: $builtApk"
}

# --- 3. Copiar APK a build\installer\Admivida.apk --------------------------
$finalApk = Join-Path $outDir 'Admivida.apk'
Copy-Item $builtApk -Destination $finalApk -Force

# --- 4. Generar manifiesto latest-android.json (UTF-8 sin BOM) -------------
$hash = (Get-FileHash $finalApk -Algorithm SHA256).Hash.ToLower()

$whatsNewFile = Join-Path $root 'releases\whats_new.json'
$whatsNewList = @()
$historyList = @()
if (Test-Path $whatsNewFile) {
    try {
        $parsedNotes = [IO.File]::ReadAllText($whatsNewFile, [System.Text.Encoding]::UTF8) | ConvertFrom-Json
        if ($parsedNotes.whatsNew) { $whatsNewList = $parsedNotes.whatsNew }
        if ($parsedNotes.history) { $historyList = $parsedNotes.history }
        if (-not $Notes -and $parsedNotes.releaseNotes) { $Notes = $parsedNotes.releaseNotes }
    } catch {}
}

$manifest = [ordered]@{
    versionCode  = [int]$versionCode
    versionName  = $versionNameFull
    downloadUrl  = 'https://minio.pacosotelo.com/admivida-bucket/releases/Admivida.apk'
    sha256       = $hash
    mandatory    = [bool]$Mandatory
    releaseNotes = $Notes
    whatsNew     = $whatsNewList
    history      = $historyList
    publishedAt  = (Get-Date).ToString('o')
}
$json = $manifest | ConvertTo-Json -Depth 6
$manifestPath = Join-Path $outDir 'latest-android.json'
[System.IO.File]::WriteAllText($manifestPath, $json, (New-Object System.Text.UTF8Encoding $false))

Write-Host ""
Write-Host "==> Listo!" -ForegroundColor Green
Write-Host "    APK        : $finalApk"
Write-Host "    Manifiesto : $manifestPath"
Write-Host "    SHA-256    : $hash"
Write-Host ""



Write-Host "Para produccion, sube AMBOS archivos a MinIO (https://minio.pacosotelo.com):" -ForegroundColor Yellow
Write-Host "  Bucket   : admivida-bucket" -ForegroundColor Cyan
Write-Host "  Carpeta  : releases/" -ForegroundColor Cyan
Write-Host "  Archivos : Admivida.apk y latest-android.json" -ForegroundColor Cyan
