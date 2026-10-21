/// Busca na transcrição, sem diferenciar maiúsculas nem acentos.
library;

const _from = 'áàâãäåéèêëíìîïóòôõöúùûüçñÁÀÂÃÄÅÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇÑ';
const _to = 'aaaaaaeeeeiiiiooooouuuucnaaaaaaeeeeiiiiooooouuuucn';

/// Minúsculas e sem acento, preservando o comprimento (índices batem com o
/// texto original).
String foldForSearch(String s) {
  final buf = StringBuffer();
  for (final unit in s.split('')) {
    final i = _from.indexOf(unit);
    buf.write(i >= 0 ? _to[i] : unit.toLowerCase());
  }
  return buf.toString();
}

/// Trechos de [text] que casam com [query], como pares (início, fim).
List<(int, int)> matchRanges(String text, String query) {
  final q = foldForSearch(query.trim());
  if (q.isEmpty) return const [];
  final t = foldForSearch(text);
  final out = <(int, int)>[];
  var from = 0;
  while (true) {
    final i = t.indexOf(q, from);
    if (i < 0) break;
    out.add((i, i + q.length));
    from = i + q.length;
  }
  return out;
}
