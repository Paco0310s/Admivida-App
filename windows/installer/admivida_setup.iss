; ============================================================================
;  Instalador de Admivida para Windows (Inno Setup 6)
;  No compiles este archivo a mano: usa  scripts\build_windows_installer.ps1
;  (compila Flutter, agrega las DLL de Visual C++, genera el .exe y latest.json)
; ============================================================================

#ifndef MyAppVersion
  #define MyAppVersion "0.0.0"
#endif

#define MyAppName "Admivida"
#define MyAppPublisher "Paco Sotelo"
#define MyAppURL "https://admivida.pacosotelo.com"
#define MyAppExeName "admivida.exe"
#define BuildDir "..\..\build\windows\x64\runner\Release"

[Setup]
; IMPORTANTE: no cambies este AppId; es lo que permite que cada versión nueva
; se instale ENCIMA de la anterior (actualización) en lugar de duplicarse.
AppId={{8F3C2A71-5B4E-4D2A-9C1F-6E7B8A9D0C12}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
VersionInfoVersion={#MyAppVersion}

; Instalación por usuario (sin permisos de administrador / sin UAC),
; así la app puede actualizarse sola en cualquier caja.
PrivilegesRequired=lowest
DefaultDirName={localappdata}\Programs\{#MyAppName}
DefaultGroupName={#MyAppName}
DisableDirPage=yes
DisableProgramGroupPage=yes

ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible

OutputDir=..\..\build\installer
OutputBaseFilename=AdmividaSetup
SetupIconFile=..\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\{#MyAppExeName}
UninstallDisplayName={#MyAppName}

Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern

; Cierra la app si sigue abierta al momento de actualizar
CloseApplications=force
RestartApplications=no

[Languages]
Name: "spanish"; MessagesFile: "compiler:Languages\Spanish.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
; Todo lo que genera "flutter build windows --release" (+ DLL de Visual C++ copiadas por el script)
Source: "{#BuildDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[InstallDelete]
; Limpia los assets de la versión anterior para no dejar archivos huérfanos
Type: filesandordirs; Name: "{app}\data\flutter_assets"

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
; Sin "skipifsilent": en la actualización automática (/SILENT) también vuelve a abrir la app.
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#MyAppName}}"; Flags: nowait postinstall

