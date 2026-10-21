/// Comandos que dependem do sistema operacional: instalação das ferramentas e
/// notificação de fim. Funções puras: o SO entra por parâmetro.
library;

import 'binary_locator.dart';

class InstallCommand {
  const InstallCommand(this.tool, this.command);

  /// Ferramenta que o comando instala (para mostrar só as que faltam).
  final Tool tool;
  final String command;
}

class InstallGuide {
  const InstallGuide(this.label, this.commands, this.note);
  final String label;
  final List<InstallCommand> commands;
  final String note;
}

/// Ordem das abas da Tela 2.
const installOsOrder = ['macos', 'windows', 'linux'];

const installGuides = <String, InstallGuide>{
  'macos': InstallGuide(
    'macOS',
    [
      InstallCommand(Tool.ffmpeg, 'brew install ffmpeg'),
      InstallCommand(Tool.whisper, 'brew install whisper-cpp'),
    ],
    'Usa o Homebrew. Não tem? Instale em brew.sh e rode o comando acima.',
  ),
  'windows': InstallGuide('Windows', [
    InstallCommand(Tool.ffmpeg, 'winget install Gyan.FFmpeg'),
    // Não há pacote do whisper.cpp no winget: baixa o zip oficial para a
    // pasta que o BinaryLocator procura no Windows.
    InstallCommand(
      Tool.whisper,
      r'$d="$env:LOCALAPPDATA\dev.fqet.falaqueeutranscrevo\bin"; '
      r'iwr https://github.com/ggml-org/whisper.cpp/releases/latest/download/whisper-bin-x64.zip -OutFile "$env:TEMP\whisper.zip"; '
      r'Expand-Archive "$env:TEMP\whisper.zip" $d -Force',
    ),
  ], 'Rode no PowerShell. Depois feche e abra o app de novo.'),
  'linux': InstallGuide(
    'Linux',
    [
      InstallCommand(Tool.ffmpeg, 'sudo apt install ffmpeg'),
      InstallCommand(
        Tool.whisper,
        'sudo snap install whisper-cpp && sudo snap alias whisper-cpp.cli whisper-cli',
      ),
    ],
    'Exemplo para Ubuntu e Debian. Em outras distros, use o gerenciador de pacotes equivalente.',
  ),
};

/// Comandos da aba [os] só para as ferramentas em [missing]. No macOS, quando
/// faltam as duas, vira um comando só (`brew install ffmpeg whisper-cpp`).
List<String> installCommandsFor(String os, Set<Tool> missing) {
  final guide = installGuides[os]!;
  final cmds = guide.commands.where((c) => missing.contains(c.tool)).toList();
  if (os == 'macos' && cmds.length == 2) {
    return ['brew install ffmpeg whisper-cpp'];
  }
  return [for (final c in cmds) c.command];
}

/// Aba pré-selecionada: o SO atual, ou macOS se for outro.
String defaultInstallTab(String os) =>
    installGuides.containsKey(os) ? os : 'macos';

/// Executável e argumentos para mostrar uma notificação do sistema, ou `null`
/// se o SO não for suportado.
(String, List<String>)? notificationCommand(
  String os,
  String title,
  String body,
) {
  switch (os) {
    case 'macos':
      String q(String s) => s.replaceAll(r'\', r'\\').replaceAll('"', r'\"');
      return (
        'osascript',
        ['-e', 'display notification "${q(body)}" with title "${q(title)}"'],
      );
    case 'linux':
      return ('notify-send', ['--app-name=$title', title, body]);
    case 'windows':
      String q(String s) => s.replaceAll("'", "''");
      return (
        'powershell',
        [
          '-NoProfile',
          '-Command',
          "Add-Type -AssemblyName System.Windows.Forms; "
              "\$n = New-Object System.Windows.Forms.NotifyIcon; "
              "\$n.Icon = [System.Drawing.SystemIcons]::Information; "
              "\$n.Visible = \$true; "
              "\$n.ShowBalloonTip(5000, '${q(title)}', '${q(body)}', 'Info'); "
              "Start-Sleep -Seconds 6; \$n.Dispose()",
        ],
      );
  }
  return null;
}

/// Executável e argumentos para mostrar [path] no gerenciador de arquivos do
/// sistema, com o arquivo selecionado quando o SO permite.
(String, List<String>)? revealCommand(String os, String path) => switch (os) {
  'macos' => ('open', ['-R', path]),
  'windows' => ('explorer', ['/select,', path]),
  'linux' => ('xdg-open', [_dirname(path)]),
  _ => null,
};

String _dirname(String path) {
  final i = path.lastIndexOf('/');
  return i <= 0 ? '/' : path.substring(0, i);
}
