; Instalador do Windows (Inno Setup 6). Gerado no GitHub Actions:
;   iscc /DAppVersion=0.1.0 /DSourceDir=<pasta Release> packaging\windows\installer.iss
#ifndef AppVersion
  #define AppVersion "0.0.0"
#endif
#ifndef SourceDir
  #define SourceDir "..\..\build\windows\x64\runner\Release"
#endif

[Setup]
AppId={{6E2C1A84-3F5B-4C1E-9B7D-FA1A0E7C2D91}
AppName=Fala que eu transcrevo!
AppVersion={#AppVersion}
AppPublisher=rssviana
AppPublisherURL=https://github.com/rssviana/fala-que-eu-transcrevo
DefaultDirName={autopf}\Fala que eu transcrevo
DefaultGroupName=Fala que eu transcrevo!
DisableProgramGroupPage=yes
OutputDir=..\..\dist
OutputBaseFilename=FalaQueEuTranscrevo-windows-setup
SetupIconFile=..\..\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\transcritor.exe
Compression=lzma2/max
SolidCompression=yes
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
WizardStyle=modern

[Languages]
Name: "ptbr"; MessagesFile: "compiler:Languages\BrazilianPortuguese.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "{#SourceDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\Fala que eu transcrevo!"; Filename: "{app}\transcritor.exe"
Name: "{autodesktop}\Fala que eu transcrevo!"; Filename: "{app}\transcritor.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\transcritor.exe"; Description: "{cm:LaunchProgram,Fala que eu transcrevo!}"; Flags: nowait postinstall skipifsilent
