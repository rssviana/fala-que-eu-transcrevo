import 'package:path/path.dart' as p;

/// Ferramentas externas que o app executa.
enum Tool {
  ffmpeg(['ffmpeg']),
  // O Homebrew antigo instalava como `whisper-cpp`; o atual, `whisper-cli`.
  whisper(['whisper-cli', 'whisper-cpp']);

  const Tool(this.names);
  final List<String> names;
}

/// Localiza binários: primeiro na pasta empacotada com o app, depois no PATH
/// e por último em pastas comuns (apps abertos pelo Finder não herdam o PATH
/// do shell, então `/opt/homebrew/bin` não aparece).
///
/// Puro: o sistema de arquivos e o ambiente entram por parâmetro.
class BinaryLocator {
  BinaryLocator({
    required this.os,
    required this.executablePath,
    required this.environment,
    required this.isFile,
  });

  /// Valor de `Platform.operatingSystem` (`macos`, `windows`, `linux`).
  final String os;

  /// Valor de `Platform.resolvedExecutable`.
  final String executablePath;
  final Map<String, String> environment;
  final bool Function(String path) isFile;

  bool get _windows => os == 'windows';
  p.Context get _p => _windows ? p.windows : p.posix;

  /// Pasta onde os binários vão empacotados junto do app.
  ///
  /// - macOS: `Fala que eu transcrevo!.app/Contents/Resources/bin`
  /// - Windows/Linux: `bin/` ao lado do executável.
  String get bundledBinDir {
    final exeDir = _p.dirname(executablePath);
    if (os == 'macos') {
      return _p.normalize(_p.join(exeDir, '..', 'Resources', 'bin'));
    }
    return _p.join(exeDir, 'bin');
  }

  List<String> get searchDirs {
    final pathVar =
        environment[_windows ? 'Path' : 'PATH'] ?? environment['PATH'] ?? '';
    final fromPath = pathVar
        .split(_windows ? ';' : ':')
        .where((d) => d.isNotEmpty);
    final extra = switch (os) {
      'macos' => ['/opt/homebrew/bin', '/usr/local/bin'],
      'linux' => ['/usr/local/bin', '/usr/bin', '/snap/bin'],
      _ => <String>[],
    };
    final dirs = <String>[bundledBinDir, ...fromPath, ...extra];
    // Remove duplicados preservando a ordem.
    return {...dirs}.toList();
  }

  /// Caminho completo do binário, ou `null` se não encontrado.
  String? find(Tool tool) {
    for (final dir in searchDirs) {
      for (final name in tool.names) {
        final candidate = _p.join(dir, _windows ? '$name.exe' : name);
        if (isFile(candidate)) return candidate;
      }
    }
    return null;
  }

  bool isBundled(String binaryPath) => _p.isWithin(bundledBinDir, binaryPath);
}
