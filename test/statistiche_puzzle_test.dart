import 'package:flutter_test/flutter_test.dart';

import 'package:arrocco/dati/modelli.dart';
import 'package:arrocco/logica/puzzle.dart';
import 'package:arrocco/logica/statistiche_puzzle.dart';

/// Test delle statistiche sui puzzle (come StatistichePuzzleTest.kt).
void main() {
  final oggi = DateTime(2026, 11, 27);

  Puzzle puzzle(int giorniFa, EsitoPuzzle esito) => Puzzle(
        id: 'p$giorniFa',
        giorno: giornoDi(oggi.subtract(Duration(days: giorniFa))),
        fen: '',
        soluzione: const [],
        ultimaMossa: '',
        rating: 1500,
        esito: esito,
      );

  test('nessun puzzle: tutto a zero', () {
    final statistiche = calcolaStatistichePuzzle([], oggi);

    expect(statistiche.affrontati, 0);
    expect(statistiche.percentualeSuccesso, 0);
    expect(statistiche.serieAttuale, 0);
  });

  test('la percentuale esclude i puzzle da fare e conta come non risolta la soluzione vista', () {
    final statistiche = calcolaStatistichePuzzle([
      puzzle(0, EsitoPuzzle.daFare),
      puzzle(1, EsitoPuzzle.risolto),
      puzzle(2, EsitoPuzzle.risoltoConErrori),
      puzzle(3, EsitoPuzzle.soluzioneVista),
    ], oggi);

    expect(statistiche.affrontati, 3);
    expect(statistiche.risolti, 2);
    expect(statistiche.alPrimoColpo, 1);
    expect(statistiche.percentualeSuccesso, 66);
  });

  test('la serie conta i giorni consecutivi fino a oggi', () {
    final statistiche = calcolaStatistichePuzzle([
      puzzle(0, EsitoPuzzle.risolto),
      puzzle(1, EsitoPuzzle.risoltoConErrori),
      puzzle(2, EsitoPuzzle.risolto),
      // manca il giorno 3: la serie si interrompe
      puzzle(4, EsitoPuzzle.risolto),
    ], oggi);

    expect(statistiche.serieAttuale, 3);
  });

  test('la serie parte da ieri se il puzzle di oggi non è ancora fatto', () {
    final statistiche = calcolaStatistichePuzzle([
      puzzle(0, EsitoPuzzle.daFare),
      puzzle(1, EsitoPuzzle.risolto),
      puzzle(2, EsitoPuzzle.risolto),
    ], oggi);

    expect(statistiche.serieAttuale, 2);
  });

  test('la soluzione vista interrompe la serie', () {
    final statistiche = calcolaStatistichePuzzle([
      puzzle(0, EsitoPuzzle.soluzioneVista),
      puzzle(1, EsitoPuzzle.risolto),
    ], oggi);

    expect(statistiche.serieAttuale, 1);
  });
}
