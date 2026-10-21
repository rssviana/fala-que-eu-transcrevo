import 'package:flutter_test/flutter_test.dart';
import 'package:transcritor/src/core/binary_locator.dart';

void main() {
  BinaryLocator mac(Set<String> files, {String path = '/usr/bin:/bin'}) =>
      BinaryLocator(
        os: 'macos',
        executablePath:
            '/Apps/Fala que eu transcrevo!.app/Contents/MacOS/transcritor',
        environment: {'PATH': path},
        isFile: files.contains,
      );

  test('macOS: pasta empacotada fica em Contents/Resources/bin', () {
    expect(
      mac({}).bundledBinDir,
      '/Apps/Fala que eu transcrevo!.app/Contents/Resources/bin',
    );
  });

  test('prefere o binário empacotado ao do PATH', () {
    final l = mac({
      '/Apps/Fala que eu transcrevo!.app/Contents/Resources/bin/ffmpeg',
      '/usr/bin/ffmpeg',
    });
    final found = l.find(Tool.ffmpeg)!;
    expect(
      found,
      '/Apps/Fala que eu transcrevo!.app/Contents/Resources/bin/ffmpeg',
    );
    expect(l.isBundled(found), isTrue);
  });

  test('cai no PATH e depois no Homebrew', () {
    expect(mac({'/bin/ffmpeg'}).find(Tool.ffmpeg), '/bin/ffmpeg');
    expect(
      mac({'/opt/homebrew/bin/whisper-cli'}).find(Tool.whisper),
      '/opt/homebrew/bin/whisper-cli',
    );
  });

  test('aceita o nome antigo whisper-cpp', () {
    expect(
      mac({'/usr/bin/whisper-cpp'}).find(Tool.whisper),
      '/usr/bin/whisper-cpp',
    );
  });

  test('retorna null quando não encontra', () {
    expect(mac({}).find(Tool.whisper), isNull);
  });

  test('Windows: .exe, bin ao lado do executável e Path com ;', () {
    final l = BinaryLocator(
      os: 'windows',
      executablePath: r'C:\Program Files\Transcritor\transcritor.exe',
      environment: {'Path': r'C:\Windows;C:\tools'},
      isFile: {
        r'C:\tools\ffmpeg.exe',
        r'C:\Program Files\Transcritor\bin\whisper-cli.exe',
      }.contains,
    );
    expect(l.bundledBinDir, r'C:\Program Files\Transcritor\bin');
    expect(l.find(Tool.ffmpeg), r'C:\tools\ffmpeg.exe');
    expect(
      l.find(Tool.whisper),
      r'C:\Program Files\Transcritor\bin\whisper-cli.exe',
    );
  });

  test('Linux: bin ao lado do executável', () {
    final l = BinaryLocator(
      os: 'linux',
      executablePath: '/opt/transcritor/transcritor',
      environment: {'PATH': ''},
      isFile: {'/opt/transcritor/bin/ffmpeg'}.contains,
    );
    expect(l.find(Tool.ffmpeg), '/opt/transcritor/bin/ffmpeg');
  });
}
