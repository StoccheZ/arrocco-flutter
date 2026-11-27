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
