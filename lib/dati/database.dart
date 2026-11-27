import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../logica/puzzle.dart';
import 'modelli.dart';

/// Database locale SQLite dell'app, gestito con sqflite.
///
/// Tabelle:
/// - profilo: l'account Lichess collegato (al massimo una riga);
/// - puzzle: i puzzle del giorno affrontati, con esito ed errori (RF6).
class ArroccoDatabase {
  Database? _db;

  /// Apre il database alla prima richiesta e poi riusa la stessa connessione.
  Future<Database> get _database async {
    return _db ??= await openDatabase(
      join(await getDatabasesPath(), 'arrocco.db'),
      version: 1,
      onCreate: _crea,
    );
  }

  static Future<void> _crea(Database db, int versione) async {
    await db.execute("""
      CREATE TABLE profilo (
        username TEXT PRIMARY KEY,
        nome TEXT NOT NULL
      )
    """);
    await db.execute("""
      CREATE TABLE puzzle (
        id TEXT PRIMARY KEY,
        giorno TEXT NOT NULL UNIQUE,
        fen TEXT NOT NULL,
        soluzione TEXT NOT NULL,
        ultima_mossa TEXT NOT NULL,
        rating INTEGER NOT NULL,
        esito TEXT NOT NULL DEFAULT 'DA_FARE',
        errori INTEGER NOT NULL DEFAULT 0
      )
    """);
  }

  /// Username dell'account collegato, oppure null se manca l'onboarding.
  Future<String?> leggiUsername() async {
    final righe = await (await _database).query('profilo', limit: 1);
    return righe.isEmpty ? null : righe.first['username'] as String;
  }

  /// Salva l'account collegato, sostituendo quello precedente.
  Future<void> salvaProfilo(String username, String nome) async {
    final db = await _database;
    await db.transaction((transazione) async {
      await transazione.delete('profilo');
      await transazione.insert('profilo', {'username': username, 'nome': nome});
    });
  }

  /// Scollega l'account; lo storico dei puzzle resta sul dispositivo.
  Future<void> eliminaProfilo() async {
    await (await _database).delete('profilo');
  }

  /// Puzzle del giorno indicato ("aaaa-mm-gg"), oppure null se non è ancora stato scaricato.
  Future<Puzzle?> puzzleDelGiorno(String giorno) async {
    final righe = await (await _database).query(
      'puzzle',
      where: 'giorno = ?',
      whereArgs: [giorno],
      limit: 1,
    );
    return righe.isEmpty ? null : Puzzle.daRiga(righe.first);
  }

  /// Puzzle con l'id indicato, oppure null.
  Future<Puzzle?> puzzlePerId(String id) async {
    final righe = await (await _database).query('puzzle', where: 'id = ?', whereArgs: [id], limit: 1);
    return righe.isEmpty ? null : Puzzle.daRiga(righe.first);
  }

  /// Inserisce un puzzle; se esiste già non lo sovrascrive, così l'esito resta (IGNORE).
  Future<void> inserisciPuzzle(Puzzle puzzle) async {
    await (await _database).insert(
      'puzzle',
      puzzle.comeRiga(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  /// Salva esito ed errori dopo un tentativo di risoluzione.
  Future<void> aggiornaEsito(String id, EsitoPuzzle esito, int errori) async {
    await (await _database).update(
      'puzzle',
      {'esito': esito.codice, 'errori': errori},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Tutti i puzzle affrontati, dal più recente (RF6).
  Future<List<Puzzle>> storicoPuzzle() async {
    final righe = await (await _database).query('puzzle', orderBy: 'giorno DESC');
    return righe.map(Puzzle.daRiga).toList();
  }
}
