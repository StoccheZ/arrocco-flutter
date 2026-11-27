import 'package:flutter_test/flutter_test.dart';

import 'package:arrocco/dati/modelli.dart';

void main() {
  test("dal JSON si tengono solo le cadenze gestite con almeno una partita", () {
    final utente = Utente.fromJson({
      'id': 'stocchez',
      'username': 'StoccheZ',
      'perfs': {
        'puzzle': {'games': 20, 'rating': 1657, 'prog': -60, 'prov': false},
        'blitz': {'games': 12, 'rating': 1194, 'prog': 25, 'prov': true},
        'rapid': {'games': 0, 'rating': 1500, 'prog': 0, 'prov': true},
        'storm': {'runs': 3, 'score': 20},
      },
    });

    expect(utente.id, 'stocchez');
    expect(utente.rating.map((r) => r.chiave), ['blitz', 'puzzle']);
    expect(utente.rating.first.valore, 1194);
    expect(utente.rating.first.progresso, 25);
    expect(utente.rating.first.provvisorio, isTrue);
    expect(utente.rating.last.etichetta, 'Puzzle');
  });

  test('profilo senza perfs', () {
    final utente = Utente.fromJson({'id': 'nuovo', 'username': 'Nuovo'});

    expect(utente.rating, isEmpty);
  });
}
