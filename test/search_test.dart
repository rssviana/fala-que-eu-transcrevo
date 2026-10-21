import 'package:flutter_test/flutter_test.dart';
import 'package:transcritor/src/core/search.dart';

void main() {
  test('ignora maiúsculas e acentos e preserva os índices', () {
    expect(foldForSearch('Ação É'), 'acao e');
    expect(matchRanges('A canção e a cancao', 'CANÇÃO'), [(2, 8), (13, 19)]);
  });

  test('busca vazia não destaca nada', () {
    expect(matchRanges('texto', '  '), isEmpty);
    expect(matchRanges('texto', 'zzz'), isEmpty);
  });
}
