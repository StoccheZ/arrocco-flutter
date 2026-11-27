import 'package:flutter_test/flutter_test.dart';

import 'package:arrocco/logica/puzzle.dart';
import 'package:arrocco/logica/scacchi.dart';

/// Test della risoluzione del puzzle (come PuzzleTest.kt), sul puzzle Lichess "bNUjA".
void main() {
  const fen = 'r1b2rk1/p5p1/2pq3p/n7/4P3/5p2/PPP1BPPP/R1BQK2R b KQ - 0 1';
  const soluzione = ['f3g2', 'h1g1', 'd6h2'];
  StatoPuzzle inizio() => iniziaPuzzle(fen, soluzione, 'd3e4');
  Casa c(String nome) => Casa.daNome(nome);

  test("l'utente gioca con il colore che ha il tratto", () {
    expect(inizio().coloreUtente, ColorePezzo.nero);
    expect(inizio().esito, EsitoPuzzle.daFare);
  });

  test("mossa corretta: viene giocata e tocca all'avversario", () {
    final tentativo = inizio().tentaMossa(c('f3'), c('g2'));

    expect(tentativo.corretto, isTrue);
    expect(tentativo.stato.indice, 1);
    expect(tentativo.stato.toccaAllAvversario, isTrue);
    expect(tentativo.stato.posizione.pezzoIn(c('g2')), const Pezzo(TipoPezzo.pedone, ColorePezzo.nero));
  });

  test('mossa sbagliata: conta un errore e lascia la posizione', () {
    final iniziale = inizio();
    final tentativo = iniziale.tentaMossa(c('d6'), c('d1'));

    expect(tentativo.corretto, isFalse);
    expect(tentativo.stato.errori, 1);
    expect(tentativo.stato.posizione, same(iniziale.posizione));
  });

  test('soluzione senza errori: risolto', () {
    final dopoRisposta = inizio().tentaMossa(c('f3'), c('g2')).stato.giocaRispostaAvversario();
    final finale = dopoRisposta.tentaMossa(c('d6'), c('h2')).stato;

    expect(finale.completato, isTrue);
    expect(finale.esito, EsitoPuzzle.risolto);
  });

  test('soluzione con un errore: risolto con errori', () {
    final conErrore = inizio().tentaMossa(c('a5'), c('c4')).stato;
    final dopoRisposta = conErrore.tentaMossa(c('f3'), c('g2')).stato.giocaRispostaAvversario();
    final finale = dopoRisposta.tentaMossa(c('d6'), c('h2')).stato;

    expect(finale.esito, EsitoPuzzle.risoltoConErrori);
  });

  test('mostra soluzione completa il puzzle', () {
    final finale = inizio().mostraSoluzione();

    expect(finale.completato, isTrue);
    expect(finale.esito, EsitoPuzzle.soluzioneVista);
    expect(finale.ultimaMossa, 'd6h2');
    expect(finale.posizione.pezzoIn(c('h2')), const Pezzo(TipoPezzo.donna, ColorePezzo.nero));
  });

  test('il codice salvato nel database torna allo stesso esito', () {
    for (final esito in EsitoPuzzle.values) {
      expect(EsitoPuzzle.daCodice(esito.codice), esito);
    }
  });
}
