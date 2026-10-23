# =============================================================================
#  Genera el instalador de Admivida para Windows + el manifiesto de actualizacion
#
#  Uso (desde la raiz del proyecto):
#    .\scripts\build_windows_installer.ps1
#    .\scripts\build_windows_installer.ps1 -Notes "Nuevo escaner en productos"
#    .\scripts\build_windows_installer.ps1 -Mandatory -Notes "Correccion importante"
#
#  Resultado en build\installer\ :
#    - AdmividaSetup.exe  -> subir a  <servidor>/downloads/AdmividaSetup.exe
#    - latest.json        -> subir a  <servidor>/downloads/latest.json
#
#  Requisitos: Flutter y Inno Setup 6 o 7 (https://jrsoftware.org/isdl.php)
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

# --- 2. Compilar Flutter en Release ----------------------------------------
$releaseDir = Join-Path $root 'build\windows\x64\runner\Release'
if (-not $SkipFlutterBuild) {
    Write-Host "==> flutter build windows --release" -ForegroundColor Cyan
    flutter build windows --release --build-name=$versionName --build-number=$versionCode
    if ($LASTEXITCODE -ne 0) { throw "Fallo flutter build windows" }
}
if (-not (Test-Path (Join-Path $releaseDir 'admivida.exe'))) {
    throw "No se encontro $releaseDir\admivida.exe"
}

# --- 3. Incluir runtime de Visual C++ (para PCs que no lo tienen instalado) --
$vcDlls = @('msvcp140.dll', 'vcruntime140.dll', 'vcruntime140_1.dll')
foreach ($dll in $vcDlls) {
    $src = Join-Path $env:WINDIR "System32\$dll"
    if (Test-Path $src) {
        Copy-Item $src -Destination $releaseDir -Force
    } else {
        Write-Warning "No se encontro $src (instala Visual C++ Redistributable x64 en esta PC)"
    }
}

# --- 4. Buscar el compilador de Inno Setup ---------------------------------
$iscc = $null
$cmd = Get-Command 'iscc.exe' -ErrorAction SilentlyContinue
if ($cmd) { $iscc = $cmd.Source }
if (-not $iscc) {
    $candidates = @(
        "${env:ProgramFiles(x86)}\Inno Setup 7\ISCC.exe",
        "$env:ProgramFiles\Inno Setup 7\ISCC.exe",
        "$env:LOCALAPPDATA\Programs\Inno Setup 7\ISCC.exe",
        "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe",
        "$env:ProgramFiles\Inno Setup 6\ISCC.exe",
        "$env:LOCALAPPDATA\Programs\Inno Setup 6\ISCC.exe"
    )
    $iscc = $candidates | Where-Object { Test-Path $_ } | Select-Object -First 1
}
if (-not $iscc) {
    throw "No se encontro Inno Setup (6 o 7). Descargalo de https://jrsoftware.org/isdl.php"
}

# --- 5. Generar instalador -------------------------------------------------
Write-Host "==> Generando instalador con Inno Setup" -ForegroundColor Cyan
& $iscc "/DMyAppVersion=$versionName" (Join-Path $root 'windows\installer\admivida_setup.iss')
if ($LASTEXITCODE -ne 0) { throw "Fallo Inno Setup" }

$outDir = Join-Path $root 'build\installer'
$setupPath = Join-Path $outDir 'AdmividaSetup.exe'

# --- 6. Generar manifiesto latest.json (UTF-8 sin BOM) ---------------------
$hash = (Get-FileHash $setupPath -Algorithm SHA256).Hash.ToLower()

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
    downloadUrl  = 'https://minio.pacosotelo.com/admivida-bucket/releases/AdmividaSetup.exe'
    sha256       = $hash
    mandatory    = [bool]$Mandatory
    releaseNotes = $Notes
    whatsNew     = $whatsNewList
    history      = $historyList
    publishedAt  = (Get-Date).ToString('o')
}
$json = $manifest | ConvertTo-Json -Depth 6
$manifestPath = Join-Path $outDir 'latest.json'
[System.IO.File]::WriteAllText($manifestPath, $json, (New-Object System.Text.UTF8Encoding $false))

Write-Host ""
Write-Host "==> Listo!" -ForegroundColor Green
Write-Host "    Instalador : $setupPath"
Write-Host "    Manifiesto : $manifestPath"
Write-Host "    SHA-256    : $hash"
Write-Host ""



Write-Host "Para produccion, sube AMBOS archivos a MinIO (https://minio.pacosotelo.com):" -ForegroundColor Yellow
Write-Host "  Bucket : admivida-bucket" -ForegroundColor Cyan
Write-Host "  Carpeta: releases/" -ForegroundColor Cyan
Write-Host "  Archivos: AdmividaSetup.exe y latest.json" -ForegroundColor Cyan
