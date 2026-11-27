import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:material_ui/material_ui.dart';

import 'package:arrocco/dati/lichess_api.dart';
import 'package:arrocco/dati/modelli.dart';
import 'package:arrocco/schermate/onboarding.dart';
import 'package:arrocco/schermate/schermata_principale.dart';

const String _profiloJson =
    '{"id":"stocchez","username":"StoccheZ","perfs":{"blitz":{"games":12,"rating":1194,"prog":25}}}';

/// Client finto: risponde con il profilo oppure con 404, senza andare in rete.
LichessApi _apiFinta({bool utenteEsiste = true}) => LichessApi(
      client: MockClient((richiesta) async => utenteEsiste
          ? http.Response(_profiloJson, 200)
          : http.Response('{"error":"Not found"}', 404)),
    );

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
    await tester.pumpWidget(MaterialApp(
      home: SchermataPrincipale(username: 'stocchez', api: _apiFinta(), onScollega: () {}),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Ciao, StoccheZ'), findsOneWidget);
    expect(find.text('Blitz'), findsOneWidget);
    expect(find.text('1194'), findsOneWidget);
    expect(find.text('+25'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.extension));
    await tester.pumpAndSettle();

    expect(find.text('Puzzle del giorno in arrivo'), findsOneWidget);
  });
}
