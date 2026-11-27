import 'database.dart';
import 'lichess_api.dart';
import 'modelli.dart';

/// Gestisce il puzzle del giorno e il suo storico (RF3–RF6).
///
/// Unisce le due fonti di dati: il database locale e le API di Lichess.
class PuzzleRepository {
  PuzzleRepository({required LichessApi api, required ArroccoDatabase database})
      : _api = api,
        _database = database;

  final LichessApi _api;
  final ArroccoDatabase _database;

  /// Puzzle di oggi: dal database se già scaricato, altrimenti da Lichess.
  Future<Puzzle> puzzleDiOggi() async {
    final oggi = giornoDi(DateTime.now());
    final salvato = await _database.puzzleDelGiorno(oggi);
    if (salvato != null) return salvato;

    final scaricato = await _api.getPuzzleDelGiorno(oggi);
    await _database.inserisciPuzzle(scaricato);
    // Si rilegge per id: se il puzzle era già presente se ne conserva l'esito
    return await _database.puzzlePerId(scaricato.id) ?? scaricato;
  }

  /// Salva esito ed errori del puzzle.
  Future<void> salvaEsito(Puzzle puzzle) =>
      _database.aggiornaEsito(puzzle.id, puzzle.esito, puzzle.errori);

  /// Tutti i puzzle affrontati, dal più recente (RF6).
  Future<List<Puzzle>> storico() => _database.storicoPuzzle();
}
