import 'scacchi.dart';

/// Esito di un puzzle, salvato nel database con il suo codice (RF6).
enum EsitoPuzzle {
  daFare('DA_FARE', 'Da fare'),
  risolto('RISOLTO', 'Risolto'),
  risoltoConErrori('RISOLTO_CON_ERRORI', 'Risolto con errori'),
  soluzioneVista('SOLUZIONE_VISTA', 'Soluzione vista');

  const EsitoPuzzle(this.codice, this.etichetta);

  /// Valore salvato nella colonna "esito" (gli stessi nomi dell'app Kotlin).
  final String codice;

  /// Testo da mostrare all'utente.
  final String etichetta;

  /// Esito corrispondente al codice salvato; DA_FARE se sconosciuto.
  static EsitoPuzzle daCodice(String codice) =>
      values.firstWhere((esito) => esito.codice == codice, orElse: () => daFare);
}

/// Stato di risoluzione di un puzzle, tradotto da Puzzle.kt.
///
/// Le mosse della soluzione si alternano: indici pari = utente,
/// indici dispari = risposta automatica dell'avversario.
class StatoPuzzle {
  const StatoPuzzle({
    required this.posizione,
    required this.soluzione,
    required this.coloreUtente,
    this.indice = 0,
    this.errori = 0,
    this.soluzioneVista = false,
    this.ultimaMossa,
  });

  final Posizione posizione;
  final List<String> soluzione;
  final ColorePezzo coloreUtente;

  /// Indice della prossima mossa da giocare nella soluzione.
  final int indice;
  final int errori;
  final bool soluzioneVista;

  /// Ultima mossa giocata, in UCI, da evidenziare sulla scacchiera.
  final String? ultimaMossa;

  bool get completato => indice >= soluzione.length;

  /// true se la prossima mossa è la risposta automatica dell'avversario.
  bool get toccaAllAvversario => !completato && indice.isOdd;

  EsitoPuzzle get esito {
    if (!completato) return EsitoPuzzle.daFare;
    if (soluzioneVista) return EsitoPuzzle.soluzioneVista;
    return errori == 0 ? EsitoPuzzle.risolto : EsitoPuzzle.risoltoConErrori;
  }

  StatoPuzzle _copia({
    Posizione? posizione,
    int? indice,
    int? errori,
    bool? soluzioneVista,
    String? ultimaMossa,
  }) {
    return StatoPuzzle(
      posizione: posizione ?? this.posizione,
      soluzione: soluzione,
      coloreUtente: coloreUtente,
      indice: indice ?? this.indice,
      errori: errori ?? this.errori,
      soluzioneVista: soluzioneVista ?? this.soluzioneVista,
      ultimaMossa: ultimaMossa ?? this.ultimaMossa,
    );
  }

  /// Verifica la mossa dell'utente (RF4) confrontandola con quella attesa.
  ///
  /// Si confrontano solo casa di partenza e di arrivo: l'eventuale promozione
  /// è presa dalla soluzione. Se è corretta viene giocata, altrimenti si conta
  /// un errore e la posizione non cambia.
  Tentativo tentaMossa(Casa da, Casa a) {
    if (completato || toccaAllAvversario) return Tentativo(this, corretto: false);

    final attesa = soluzione[indice];
    if (da.nome + a.nome == attesa.substring(0, 4)) {
      return Tentativo(
        _copia(posizione: posizione.applica(attesa), indice: indice + 1, ultimaMossa: attesa),
        corretto: true,
      );
    }
    return Tentativo(_copia(errori: errori + 1), corretto: false);
  }

  /// Gioca la risposta dell'avversario prevista dalla soluzione, se è il suo turno.
  StatoPuzzle giocaRispostaAvversario() {
    if (!toccaAllAvversario) return this;
    final risposta = soluzione[indice];
    return _copia(posizione: posizione.applica(risposta), indice: indice + 1, ultimaMossa: risposta);
  }

  /// Gioca tutte le mosse rimanenti della soluzione (RF5).
  StatoPuzzle mostraSoluzione() {
    var stato = _copia(soluzioneVista: true);
    while (!stato.completato) {
      final mossa = stato.soluzione[stato.indice];
      stato = stato._copia(
        posizione: stato.posizione.applica(mossa),
        indice: stato.indice + 1,
        ultimaMossa: mossa,
      );
    }
    return stato;
  }
}

/// Risultato di un tentativo: il nuovo stato e se la mossa era corretta.
class Tentativo {
  const Tentativo(this.stato, {required this.corretto});

  final StatoPuzzle stato;
  final bool corretto;
}

/// Prepara un puzzle: l'utente gioca con il colore che ha il tratto nella posizione FEN.
StatoPuzzle iniziaPuzzle(String fen, List<String> soluzione, String? ultimaMossa) {
  final posizione = leggiFen(fen);
  return StatoPuzzle(
    posizione: posizione,
    soluzione: soluzione,
    coloreUtente: posizione.turno,
    ultimaMossa: (ultimaMossa == null || ultimaMossa.isEmpty) ? null : ultimaMossa,
  );
}
