/// Identificador do app e pastas que dependem dele.
library;

import 'package:path/path.dart' as p;

/// Mesmo identificador em todas as plataformas (bundle id no macOS,
/// APPLICATION_ID no Linux e nome das pastas no Windows).
const appId = 'dev.fqet.falaqueeutranscrevo';

/// Pasta de dados do app (onde ficam os modelos), quando o app decide o
/// caminho por conta própria. `null` = usar o `path_provider`, que no macOS e
/// no Linux já usa o [appId]. No Windows o `path_provider` montaria
/// `%APPDATA%\<empresa>\<produto>`; aqui fica `%APPDATA%\dev.fqet.falaqueeutranscrevo`.
String? appDataDir(String os, Map<String, String> environment) {
  if (os != 'windows') return null;
  final appData = environment['APPDATA'];
  return appData == null ? null : p.windows.join(appData, appId);
}

/// Pasta onde o comando de instalação do Windows extrai o whisper-cli.
String windowsUserBinDir(String localAppData) =>
    p.windows.join(localAppData, appId, 'bin');
