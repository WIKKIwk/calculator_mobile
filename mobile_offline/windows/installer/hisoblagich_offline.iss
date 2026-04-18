; Bitta yuklab olinadigan o'rnatuvchi: Release ichidagi barcha fayllarni tanlangan papkaga yozadi.
; Yo'llar shu .iss fayl (mobile_offline/windows/installer/) ga nisbatan.

#define MyAppName "Hisoblagich (offline)"
#define MyAppVersion "2.0.0"
#define MyAppPublisher "Hisoblagich"
#define MyAppExeName "calculator_offline.exe"
#define ReleaseDir "..\\..\\build\\windows\\x64\\runner\\Release"

[Setup]
AppId={{F4E8B2A1-7C3D-4F6E-9B1A-2D8E4C6F0A5B}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={localappdata}\Programs\HisoblagichOffline
DefaultGroupName={#MyAppName}
PrivilegesRequired=lowest
OutputDir=..\..\build\installer_out
OutputBaseFilename=hisoblagich-offline-setup
ArchitecturesInstallIn64BitMode=x64
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
DisableProgramGroupPage=no
UninstallDisplayIcon={app}\{#MyAppExeName}

[Tasks]
Name: "desktopicon"; Description: "Create desktop shortcut"; GroupDescription: "Optional:"; Flags: unchecked

[Files]
Source: "{#ReleaseDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Flags: nowait postinstall skipifsilent
