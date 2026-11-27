import '../dati/modelli.dart';
import 'puzzle.dart';

/// Statistiche sui puzzle affrontati (RF6), come StatistichePuzzle.kt.
class StatistichePuzzle {
  const StatistichePuzzle({
    this.affrontati = 0,
    this.risolti = 0,
    this.alPrimoColpo = 0,
    this.serieAttuale = 0,
  });

  /// Puzzle con un esito (esclusi quelli ancora da fare).
  final int affrontati;

  /// Puzzle completati dall'utente, con o senza errori (esclusa la soluzione vista).
  final int risolti;
  final int alPrimoColpo;

  /// Giorni consecutivi con il puzzle risolto, fino a oggi o a ieri.
  final int serieAttuale;

  /// Percentuale di puzzle risolti sul totale affrontato, da 0 a 100.
  int get percentualeSuccesso => affrontati == 0 ? 0 : risolti * 100 ~/ affrontati;
}

bool _risolto(Puzzle puzzle) =>
    puzzle.esito == EsitoPuzzle.risolto || puzzle.esito == EsitoPuzzle.risoltoConErrori;

/// Calcola le statistiche a partire da tutti i puzzle salvati.
/// [oggi] è il giorno corrente (conta solo la data, non l'ora).
StatistichePuzzle calcolaStatistichePuzzle(List<Puzzle> puzzle, DateTime oggi) {
  final affrontati = puzzle.where((p) => p.esito != EsitoPuzzle.daFare).toList();
  final giorniRisolti = puzzle.where(_risolto).map((p) => p.giorno).toSet();

  // Si lavora in UTC sulle sole date, così il cambio dell'ora legale non sposta i giorni
  var giorno = DateTime.utc(oggi.year, oggi.month, oggi.day);
  // La serie conta anche se il puzzle di oggi non è ancora stato fatto: si parte da ieri
  if (!giorniRisolti.contains(giornoDi(giorno))) {
    giorno = giorno.subtract(const Duration(days: 1));
  }
  var serie = 0;
  while (giorniRisolti.contains(giornoDi(giorno))) {
    serie++;
    giorno = giorno.subtract(const Duration(days: 1));
  }

  return StatistichePuzzle(
    affrontati: affrontati.length,
    risolti: affrontati.where(_risolto).length,
    alPrimoColpo: affrontati.where((p) => p.esito == EsitoPuzzle.risolto).length,
    serieAttuale: serie,
  );
}
