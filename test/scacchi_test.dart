import 'package:flutter_test/flutter_test.dart';

import 'package:arrocco/logica/scacchi.dart';

/// Test della lettura del FEN e dell'applicazione delle mosse (come ScacchiTest.kt).
void main() {
  const posizioneIniziale = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';
  Casa c(String nome) => Casa.daNome(nome);

  test('nome algebrico delle case', () {
    expect(c('e4'), Casa(4, 3));
    expect(Casa(7, 7).nome, 'h8');
  });

  test('FEN della posizione iniziale', () {
    final posizione = leggiFen(posizioneIniziale);

    expect(posizione.pezzi.length, 32);
    expect(posizione.turno, ColorePezzo.bianco);
    expect(posizione.pezzoIn(c('e1')), const Pezzo(TipoPezzo.re, ColorePezzo.bianco));
    expect(posizione.pezzoIn(c('d8')), const Pezzo(TipoPezzo.donna, ColorePezzo.nero));
    expect(posizione.pezzoIn(c('e4')), isNull);
  });

  test('FEN di un puzzle di Lichess con il Nero al tratto', () {
    final posizione = leggiFen('r1b2rk1/p5p1/2pq3p/n7/4P3/5p2/PPP1BPPP/R1BQK2R b KQ - 0 1');

    expect(posizione.turno, ColorePezzo.nero);
    expect(posizione.pezzoIn(c('g8')), const Pezzo(TipoPezzo.re, ColorePezzo.nero));
    expect(posizione.pezzoIn(c('f3')), const Pezzo(TipoPezzo.pedone, ColorePezzo.nero));
  });

  test('FEN non valido', () {
    expect(() => leggiFen('8/8/8 w - - 0 1'), throwsFormatException);
  });

  test('mossa normale e cambio di turno', () {
    final dopo = leggiFen(posizioneIniziale).applica('e2e4');

    expect(dopo.pezzoIn(c('e2')), isNull);
    expect(dopo.pezzoIn(c('e4')), const Pezzo(TipoPezzo.pedone, ColorePezzo.bianco));
    expect(dopo.turno, ColorePezzo.nero);
  });

  test('arrocco corto e lungo', () {
    final corto = leggiFen('r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1').applica('e1g1');
    expect(corto.pezzoIn(c('g1')), const Pezzo(TipoPezzo.re, ColorePezzo.bianco));
    expect(corto.pezzoIn(c('f1')), const Pezzo(TipoPezzo.torre, ColorePezzo.bianco));
    expect(corto.pezzoIn(c('h1')), isNull);

    final lungo = leggiFen('r3k2r/8/8/8/8/8/8/R3K2R b KQkq - 0 1').applica('e8c8');
    expect(lungo.pezzoIn(c('c8')), const Pezzo(TipoPezzo.re, ColorePezzo.nero));
    expect(lungo.pezzoIn(c('d8')), const Pezzo(TipoPezzo.torre, ColorePezzo.nero));
    expect(lungo.pezzoIn(c('a8')), isNull);
  });

  test('en passant', () {
    final dopo = leggiFen('4k3/8/8/3pP3/8/8/8/4K3 w - d6 0 1').applica('e5d6');

    expect(dopo.pezzoIn(c('d6')), const Pezzo(TipoPezzo.pedone, ColorePezzo.bianco));
    expect(dopo.pezzoIn(c('d5')), isNull);
  });

  test('promozione', () {
    final dopo = leggiFen('4k3/P7/8/8/8/8/8/4K3 w - - 0 1').applica('a7a8q');

    expect(dopo.pezzoIn(c('a8')), const Pezzo(TipoPezzo.donna, ColorePezzo.bianco));
  });
}
