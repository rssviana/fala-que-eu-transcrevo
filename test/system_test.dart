import 'package:flutter_test/flutter_test.dart';
import 'package:transcritor/src/core/binary_locator.dart';
import 'package:transcritor/src/core/system.dart';

void main() {
  const both = {Tool.ffmpeg, Tool.whisper};

  test('macOS: um comando só quando faltam as duas ferramentas', () {
    expect(installCommandsFor('macos', both), [
      'brew install ffmpeg whisper-cpp',
    ]);
    expect(installCommandsFor('macos', {Tool.whisper}), [
      'brew install whisper-cpp',
    ]);
  });

  test('mostra só os comandos das ferramentas que faltam', () {
    expect(installCommandsFor('windows', {Tool.ffmpeg}), [
      'winget install Gyan.FFmpeg',
    ]);
    final linux = installCommandsFor('linux', {Tool.whisper});
    expect(linux.single, contains('snap install whisper-cpp'));
    expect(linux.single, contains('whisper-cli'));
    expect(installCommandsFor('linux', both).length, 2);
    expect(installCommandsFor('macos', {}), isEmpty);
  });

  test('nenhum marcador de colchetes sobrou', () {
    for (final g in installGuides.values) {
      for (final c in g.commands) {
        expect(c.command, isNot(contains('[')));
      }
    }
  });

  test('Windows: comando extrai na pasta que o BinaryLocator procura', () {
    final cmd = installCommandsFor('windows', {Tool.whisper}).single;
    expect(cmd, contains(r'$env:LOCALAPPDATA\FalaQueEuTranscrevo\bin'));
    final locator = BinaryLocator(
      os: 'windows',
      executablePath: r'C:\App\transcritor.exe',
      environment: {'Path': '', 'LOCALAPPDATA': r'C:\Users\a\AppData\Local'},
      isFile: {
        r'C:\Users\a\AppData\Local\FalaQueEuTranscrevo\bin\Release\whisper-cli.exe',
      }.contains,
    );
    expect(locator.find(Tool.whisper), isNotNull);
  });

  test('aba padrão é o SO atual', () {
    expect(defaultInstallTab('linux'), 'linux');
    expect(defaultInstallTab('windows'), 'windows');
    expect(defaultInstallTab('fuchsia'), 'macos');
  });

  test('notificação por SO, com aspas escapadas', () {
    final mac = notificationCommand('macos', 'Título', 'Diz "oi"')!;
    expect(mac.$1, 'osascript');
    expect(
      mac.$2.last,
      r'display notification "Diz \"oi\"" with title "Título"',
    );
    expect(notificationCommand('linux', 'T', 'B')!.$1, 'notify-send');
    final win = notificationCommand('windows', 'T', "it's")!;
    expect(win.$1, 'powershell');
    expect(win.$2.last, contains("'it''s'"));
    expect(notificationCommand('android', 'T', 'B'), isNull);
  });

  test('mostrar o arquivo salvo na pasta', () {
    final mac = revealCommand('macos', '/a/b.txt')!;
    expect(mac.$1, 'open');
    expect(mac.$2, ['-R', '/a/b.txt']);
    expect(revealCommand('linux', '/a/b.txt')!.$2, ['/a']);
    expect(revealCommand('windows', r'C:\a\b.txt')!.$1, 'explorer');
    expect(revealCommand('android', '/a'), isNull);
  });
}
