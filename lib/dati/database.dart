import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

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
}
