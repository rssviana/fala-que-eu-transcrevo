import 'package:flutter_test/flutter_test.dart';
import 'package:transcritor/src/core/app_paths.dart';

void main() {
  test('Windows usa %APPDATA%\\dev.fqet.falaqueeutranscrevo', () {
    expect(
      appDataDir('windows', {'APPDATA': r'C:\Users\a\AppData\Roaming'}),
      r'C:\Users\a\AppData\Roaming\dev.fqet.falaqueeutranscrevo',
    );
  });

  test('macOS e Linux deixam com o path_provider (já usa o appId)', () {
    expect(appDataDir('macos', const {}), isNull);
    expect(appDataDir('linux', const {'APPDATA': '/x'}), isNull);
    expect(appDataDir('windows', const {}), isNull);
  });

  test('pasta de binários do usuário no Windows', () {
    expect(
      windowsUserBinDir(r'C:\Users\a\AppData\Local'),
      r'C:\Users\a\AppData\Local\dev.fqet.falaqueeutranscrevo\bin',
    );
  });
}
