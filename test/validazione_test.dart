import 'package:flutter_test/flutter_test.dart';

import 'package:arrocco/logica/validazione.dart';

void main() {
  test('username valido', () {
    expect(validaUsername('StoccheZ'), isNull);
    expect(validaUsername('mario_rossi-99'), isNull);
  });

  test('username vuoto', () {
    expect(validaUsername('   '), 'Inserisci il tuo username Lichess');
  });

  test('username troppo corto o troppo lungo', () {
    expect(validaUsername('a'), isNotNull);
    expect(validaUsername('a' * 31), isNotNull);
  });

  test('username con caratteri non ammessi', () {
    expect(validaUsername('mario rossi'), 'Usa solo lettere, numeri, _ e -');
    expect(validaUsername('_mario'), 'Usa solo lettere, numeri, _ e -');
  });
}
