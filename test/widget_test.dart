import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:material_ui/material_ui.dart';

import 'package:arrocco/dati/lichess_api.dart';
import 'package:arrocco/dati/modelli.dart';
import 'package:arrocco/dati/puzzle_repository.dart';
import 'package:arrocco/logica/puzzle.dart';
import 'package:arrocco/schermate/onboarding.dart';
import 'package:arrocco/schermate/puzzle.dart';
import 'package:arrocco/schermate/schermata_principale.dart';
import 'package:arrocco/schermate/storico.dart';

const String _profiloJson =
    '{"id":"stocchez","username":"StoccheZ","perfs":{"blitz":{"games":12,"rating":1194,"prog":25}}}';

/// Client finto: risponde con il profilo oppure con 404, senza andare in rete.
LichessApi _apiFinta({bool utenteEsiste = true}) => LichessApi(
      client: MockClient((richiesta) async => utenteEsiste
          ? http.Response(_profiloJson, 200)
          : http.Response('{"error":"Not found"}', 404)),
    );

/// Puzzle Lichess "bNUjA": il Nero vince con f3g2, h1g1, d6h2.
const Puzzle _puzzle = Puzzle(
  id: 'bNUjA',
  giorno: '2026-11-27',
  fen: 'r1b2rk1/p5p1/2pq3p/n7/4P3/5p2/PPP1BPPP/R1BQK2R b KQ - 0 1',
  soluzione: ['f3g2', 'h1g1', 'd6h2'],
  ultimaMossa: 'd3e4',
  rating: 1500,
);

/// Repository finto: restituisce sempre lo stesso puzzle e ricorda l'esito salvato.
class _PuzzleFinto implements PuzzleRepository {
  Puzzle? salvato;

  @override
  Future<Puzzle> puzzleDiOggi() async => _puzzle;

  @override
  Future<void> salvaEsito(Puzzle puzzle) async => salvato = puzzle;

  @override
  Future<List<Puzzle>> storico() async => [if (salvato != null) salvato!];
}

/// Schermo di un telefono (360x800), così la scacchiera è tutta visibile.
void _schermoTelefono(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('onboarding: username vuoto mostra un errore', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: SchermataOnboarding(api: _apiFinta(), onCollegato: (_) async {}),
    ));

    await tester.tap(find.text('Collega account'));
    await tester.pump();

    expect(find.text('Inserisci il tuo username Lichess'), findsOneWidget);
  });

  testWidgets('onboarding: utente inesistente', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: SchermataOnboarding(api: _apiFinta(utenteEsiste: false), onCollegato: (_) async {}),
    ));

    await tester.enterText(find.byType(TextField), 'nessuno123');
    await tester.tap(find.text('Collega account'));
    await tester.pumpAndSettle();

    expect(find.text('Utente non trovato su Lichess'), findsOneWidget);
  });

  testWidgets('onboarding: utente esistente viene collegato', (tester) async {
    Utente? collegato;
    await tester.pumpWidget(MaterialApp(
      home: SchermataOnboarding(api: _apiFinta(), onCollegato: (utente) async => collegato = utente),
    ));

    await tester.enterText(find.byType(TextField), 'StoccheZ');
    await tester.tap(find.text('Collega account'));
    await tester.pumpAndSettle();

    expect(collegato?.id, 'stocchez');
  });

  testWidgets('home mostra i rating e la barra cambia scheda', (tester) async {
    _schermoTelefono(tester);
    await tester.pumpWidget(MaterialApp(
      home: SchermataPrincipale(
        username: 'stocchez',
        api: _apiFinta(),
        puzzleRepository: _PuzzleFinto(),
        onScollega: () {},
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Ciao, StoccheZ'), findsOneWidget);
    expect(find.text('Blitz'), findsOneWidget);
    expect(find.text('1194'), findsOneWidget);
    expect(find.text('+25'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.extension));
    await tester.pumpAndSettle();

    expect(find.text('Puzzle del giorno'), findsOneWidget);
  });

  testWidgets('puzzle: mossa sbagliata, poi risoluzione e salvataggio', (tester) async {
    _schermoTelefono(tester);
    final repository = _PuzzleFinto();
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: SchermataPuzzle(repository: repository))));
    await tester.pumpAndSettle();

    expect(find.text('Muove il Nero: trova la mossa migliore'), findsOneWidget);

    Future<void> muovi(String da, String a) async {
      await tester.tap(find.byKey(ValueKey('casa_$da')));
      await tester.pump();
      await tester.tap(find.byKey(ValueKey('casa_$a')));
      await tester.pump();
    }

    await muovi('d6', 'd1');
    expect(find.text('Mossa sbagliata, riprova'), findsOneWidget);
    expect(find.text('Errori: 1'), findsOneWidget);

    await muovi('f3', 'g2');
    expect(find.text('Mossa corretta! Continua'), findsOneWidget);

    // Dopo la pausa l'avversario risponde h1g1
    await tester.pump(const Duration(milliseconds: 700));

    await muovi('d6', 'h2');
    await tester.pumpAndSettle();

    expect(find.text('Puzzle risolto con 1 errore'), findsOneWidget);
    expect(repository.salvato?.esito, EsitoPuzzle.risoltoConErrori);
    expect(repository.salvato?.errori, 1);
  });

  testWidgets('storico: statistiche ed elenco dei puzzle', (tester) async {
    _schermoTelefono(tester);
    final repository = _PuzzleFinto()..salvato = _puzzle.conEsito(EsitoPuzzle.risoltoConErrori, 2);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: SchermataStorico(repository: repository))));
    await tester.pumpAndSettle();

    expect(find.text('Storico puzzle'), findsOneWidget);
    expect(find.text('100%'), findsOneWidget);
    expect(find.text('Puzzle del 27/11/2026'), findsOneWidget);
    expect(find.text('Risolto con errori (2)'), findsOneWidget);
  });
}
