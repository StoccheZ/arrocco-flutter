import '../logica/puzzle.dart';

/// Cadenze mostrate dall'app, nell'ordine in cui compaiono in Home.
const Map<String, String> cadenzeGestite = {
  'bullet': 'Bullet',
  'blitz': 'Blitz',
  'rapid': 'Rapid',
  'classical': 'Classica',
  'puzzle': 'Puzzle',
};

/// Rating di una cadenza (RF2).
class RatingCadenza {
  const RatingCadenza({
    required this.chiave,
    required this.valore,
    required this.progresso,
    required this.partite,
    required this.provvisorio,
  });

  /// Chiave Lichess della cadenza, es. "blitz".
  final String chiave;
  final int valore;

  /// Variazione recente del rating calcolata da Lichess (campo "prog").
  final int progresso;
  final int partite;

  /// true se il rating è ancora provvisorio (poche partite giocate).
  final bool provvisorio;

  /// Nome della cadenza da mostrare, es. "Classica".
  String get etichetta => cadenzeGestite[chiave] ?? chiave;
}

/// Profilo Lichess dell'utente con i rating delle cadenze giocate.
class Utente {
  const Utente({required this.id, required this.username, required this.rating});

  /// Identificativo in minuscolo, usato nelle chiamate alle API.
  final String id;

  /// Nome visualizzato, con maiuscole e minuscole originali.
  final String username;
  final List<RatingCadenza> rating;

  /// Costruisce l'utente dalla risposta JSON di GET /api/user/{username}.
  ///
  /// Si tengono solo le cadenze gestite con almeno una partita: per le altre
  /// Lichess riporta un rating di partenza (1500) che non è significativo.
  factory Utente.fromJson(Map<String, dynamic> json) {
    final perfs = (json['perfs'] as Map<String, dynamic>?) ?? const {};
    final rating = <RatingCadenza>[];
    for (final chiave in cadenzeGestite.keys) {
      final perf = perfs[chiave];
      if (perf is! Map<String, dynamic>) continue;
      final partite = (perf['games'] as num?)?.toInt() ?? 0;
      if (partite == 0) continue;
      rating.add(RatingCadenza(
        chiave: chiave,
        valore: (perf['rating'] as num?)?.toInt() ?? 1500,
        progresso: (perf['prog'] as num?)?.toInt() ?? 0,
        partite: partite,
        provvisorio: perf['prov'] == true,
      ));
    }
    return Utente(
      id: json['id'] as String,
      username: json['username'] as String,
      rating: rating,
    );
  }
}

/// Data in formato "aaaa-mm-gg", usata come giorno del puzzle (ora locale).
String giornoDi(DateTime data) {
  String dueCifre(int n) => n.toString().padLeft(2, '0');
  return '${data.year}-${dueCifre(data.month)}-${dueCifre(data.day)}';
}

/// Puzzle del giorno salvato nel database (RF3, RF6).
class Puzzle {
  const Puzzle({
    required this.id,
    required this.giorno,
    required this.fen,
    required this.soluzione,
    required this.ultimaMossa,
    required this.rating,
    this.esito = EsitoPuzzle.daFare,
    this.errori = 0,
  });

  /// Identificativo Lichess del puzzle, es. "bNUjA".
  final String id;

  /// Giorno in cui è stato proposto, formato "aaaa-mm-gg".
  final String giorno;
  final String fen;

  /// Mosse della soluzione in formato UCI.
  final List<String> soluzione;

  /// Mossa dell'avversario che ha portato alla posizione, da evidenziare.
  final String ultimaMossa;
  final int rating;
  final EsitoPuzzle esito;
  final int errori;

  /// Costruisce il puzzle dalla risposta di GET /api/puzzle/daily.
  factory Puzzle.daJsonDelGiorno(Map<String, dynamic> json, String giorno) {
    final dati = json['puzzle'] as Map<String, dynamic>;
    final fen = dati['fen'] as String?;
    if (fen == null) throw const FormatException('Il puzzle non contiene la posizione FEN');
    return Puzzle(
      id: dati['id'] as String,
      giorno: giorno,
      fen: fen,
      soluzione: (dati['solution'] as List<dynamic>).cast<String>(),
      ultimaMossa: (dati['lastMove'] as String?) ?? '',
      rating: (dati['rating'] as num).toInt(),
    );
  }

  /// Riga letta dalla tabella "puzzle".
  factory Puzzle.daRiga(Map<String, Object?> riga) {
    final soluzione = riga['soluzione'] as String;
    return Puzzle(
      id: riga['id'] as String,
      giorno: riga['giorno'] as String,
      fen: riga['fen'] as String,
      soluzione: soluzione.isEmpty ? const [] : soluzione.split(','),
      ultimaMossa: riga['ultima_mossa'] as String,
      rating: riga['rating'] as int,
      esito: EsitoPuzzle.daCodice(riga['esito'] as String),
      errori: riga['errori'] as int,
    );
  }

  /// Riga da inserire nella tabella "puzzle"; la soluzione diventa testo separato da virgole.
  Map<String, Object?> comeRiga() => {
        'id': id,
        'giorno': giorno,
        'fen': fen,
        'soluzione': soluzione.join(','),
        'ultima_mossa': ultimaMossa,
        'rating': rating,
        'esito': esito.codice,
        'errori': errori,
      };

  /// Copia con esito ed errori aggiornati dopo un tentativo.
  Puzzle conEsito(EsitoPuzzle esito, int errori) => Puzzle(
        id: id,
        giorno: giorno,
        fen: fen,
        soluzione: soluzione,
        ultimaMossa: ultimaMossa,
        rating: rating,
        esito: esito,
        errori: errori,
      );
}
