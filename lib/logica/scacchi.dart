/// Modello minimo degli scacchi, tradotto da Scacchi.kt dell'app Kotlin:
/// lettura del FEN e applicazione delle mosse UCI, senza verifica della legalità.
library;

/// Colore di un pezzo.
enum ColorePezzo {
  bianco,
  nero;

  /// Colore dell'avversario.
  ColorePezzo get opposto => this == bianco ? nero : bianco;

  /// Nome da mostrare, es. "Bianco".
  String get nome => this == bianco ? 'Bianco' : 'Nero';
}

/// Tipo di un pezzo degli scacchi.
enum TipoPezzo { re, donna, torre, alfiere, cavallo, pedone }

/// Un pezzo: tipo e colore.
class Pezzo {
  const Pezzo(this.tipo, this.colore);

  final TipoPezzo tipo;
  final ColorePezzo colore;

  @override
  bool operator ==(Object other) =>
      other is Pezzo && other.tipo == tipo && other.colore == colore;

  @override
  int get hashCode => Object.hash(tipo, colore);

  @override
  String toString() => 'Pezzo(${tipo.name}, ${colore.name})';
}

/// Casa della scacchiera: colonna 0 = "a", riga 0 = traversa "1".
class Casa {
  Casa(this.colonna, this.riga)
      : assert(colonna >= 0 && colonna < 8 && riga >= 0 && riga < 8,
            'Casa fuori dalla scacchiera: $colonna,$riga');

  /// Crea una casa dal nome algebrico, es. "e4" -> Casa(4, 3).
  factory Casa.daNome(String nome) {
    if (nome.length != 2) throw FormatException('Nome di casa non valido: $nome');
    return Casa(nome.codeUnitAt(0) - 'a'.codeUnitAt(0), nome.codeUnitAt(1) - '1'.codeUnitAt(0));
  }

  final int colonna;
  final int riga;

  /// Nome in notazione algebrica, es. "e4".
  String get nome => '${String.fromCharCode('a'.codeUnitAt(0) + colonna)}${riga + 1}';

  @override
  bool operator ==(Object other) => other is Casa && other.colonna == colonna && other.riga == riga;

  @override
  int get hashCode => colonna * 8 + riga;

  @override
  String toString() => nome;
}

/// Posizione: dove si trovano i pezzi e a chi tocca muovere.
/// È immutabile: applicare una mossa restituisce una nuova posizione.
class Posizione {
  const Posizione(this.pezzi, this.turno);

  final Map<Casa, Pezzo> pezzi;
  final ColorePezzo turno;

  /// Pezzo presente nella casa indicata, oppure null se è vuota.
  Pezzo? pezzoIn(Casa casa) => pezzi[casa];

  /// Applica una mossa in formato UCI (es. "e2e4", "e7e8q").
  /// Gestisce i casi speciali: en passant, arrocco e promozione.
  Posizione applica(String mossaUci) {
    if (mossaUci.length < 4 || mossaUci.length > 5) {
      throw FormatException('Mossa UCI non valida: $mossaUci');
    }
    final da = Casa.daNome(mossaUci.substring(0, 2));
    final a = Casa.daNome(mossaUci.substring(2, 4));
    final pezzo = pezzi[da];
    if (pezzo == null) throw StateError('Nessun pezzo in ${da.nome}');

    final nuovi = Map<Casa, Pezzo>.of(pezzi)..remove(da);

    // En passant: un pedone che si muove in diagonale su una casa vuota cattura il pedone accanto
    if (pezzo.tipo == TipoPezzo.pedone && da.colonna != a.colonna && pezzi[a] == null) {
      nuovi.remove(Casa(a.colonna, da.riga));
    }

    // Arrocco: il re si sposta di due colonne e la torre lo scavalca
    if (pezzo.tipo == TipoPezzo.re && (a.colonna - da.colonna).abs() == 2) {
      final versoDestra = a.colonna > da.colonna;
      final torre = nuovi.remove(Casa(versoDestra ? 7 : 0, da.riga));
      if (torre != null) nuovi[Casa(versoDestra ? 5 : 3, da.riga)] = torre;
    }

    // Promozione: la quinta lettera indica il nuovo pezzo
    nuovi[a] = mossaUci.length == 5 ? Pezzo(_tipoDaLettera(mossaUci[4]), pezzo.colore) : pezzo;

    return Posizione(Map.unmodifiable(nuovi), turno.opposto);
  }
}

/// Converte la lettera FEN/UCI nel tipo di pezzo (maiuscole e minuscole indifferenti).
TipoPezzo _tipoDaLettera(String lettera) => switch (lettera.toLowerCase()) {
      'k' => TipoPezzo.re,
      'q' => TipoPezzo.donna,
      'r' => TipoPezzo.torre,
      'b' => TipoPezzo.alfiere,
      'n' => TipoPezzo.cavallo,
      'p' => TipoPezzo.pedone,
      _ => throw FormatException('Lettera di pezzo non valida: $lettera'),
    };

/// Legge una posizione in notazione FEN.
/// Usa i primi due campi: disposizione dei pezzi (dalla traversa 8 alla 1) e colore che muove.
Posizione leggiFen(String fen) {
  final campi = fen.trim().split(' ');
  final traverse = campi[0].split('/');
  if (traverse.length != 8) throw const FormatException('FEN non valido: servono 8 traverse');

  final pezzi = <Casa, Pezzo>{};
  for (var indice = 0; indice < 8; indice++) {
    final riga = 7 - indice;
    var colonna = 0;
    for (final carattere in traverse[indice].split('')) {
      final cifra = int.tryParse(carattere);
      if (cifra != null) {
        colonna += cifra;
      } else {
        if (colonna > 7) throw FormatException('FEN non valido nella traversa ${riga + 1}');
        final colore = carattere == carattere.toUpperCase() ? ColorePezzo.bianco : ColorePezzo.nero;
        pezzi[Casa(colonna, riga)] = Pezzo(_tipoDaLettera(carattere), colore);
        colonna++;
      }
    }
    if (colonna != 8) throw FormatException('FEN non valido nella traversa ${riga + 1}');
  }

  final turno = campi.length > 1 && campi[1] == 'b' ? ColorePezzo.nero : ColorePezzo.bianco;
  return Posizione(Map.unmodifiable(pezzi), turno);
}
