import 'package:material_ui/material_ui.dart';

import '../logica/scacchi.dart';

const Color _casaChiara = Color(0xFFF0D9B5);
const Color _casaScura = Color(0xFFB58863);
const Color _ultimaMossa = Color(0x99CDD26A);
const Color _selezione = Color(0x9964B5F6);

/// Forza la visualizzazione dei simboli come testo e non come emoji.
const String _stileTesto = '︎';

/// Scacchiera 8x8 interattiva, con gli stessi colori dell'app Kotlin.
///
/// [orientamento] è il colore mostrato in basso (quello dell'utente);
/// [ultimaMossa] è la mossa UCI da evidenziare, es. "d3e4".
class Scacchiera extends StatelessWidget {
  const Scacchiera({
    super.key,
    required this.posizione,
    required this.orientamento,
    required this.onCasaToccata,
    this.casaSelezionata,
    this.ultimaMossa,
  });

  final Posizione posizione;
  final ColorePezzo orientamento;
  final Casa? casaSelezionata;
  final String? ultimaMossa;
  final ValueChanged<Casa> onCasaToccata;

  @override
  Widget build(BuildContext context) {
    final mossa = ultimaMossa;
    final caseUltimaMossa = (mossa != null && mossa.length >= 4)
        ? {Casa.daNome(mossa.substring(0, 2)), Casa.daNome(mossa.substring(2, 4))}
        : const <Casa>{};

    return AspectRatio(
      aspectRatio: 1,
      child: Column(
        children: [
          for (var rigaSchermo = 0; rigaSchermo < 8; rigaSchermo++)
            Expanded(
              child: Row(
                children: [
                  for (var colonnaSchermo = 0; colonnaSchermo < 8; colonnaSchermo++)
                    Expanded(
                      child: _casaInPosizione(rigaSchermo, colonnaSchermo, caseUltimaMossa),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _casaInPosizione(int rigaSchermo, int colonnaSchermo, Set<Casa> caseUltimaMossa) {
    // Dal punto di vista del Nero la scacchiera è ruotata di 180°
    final casa = orientamento == ColorePezzo.bianco
        ? Casa(colonnaSchermo, 7 - rigaSchermo)
        : Casa(7 - colonnaSchermo, rigaSchermo);
    return _CasaScacchiera(
      key: ValueKey('casa_${casa.nome}'),
      casa: casa,
      pezzo: posizione.pezzoIn(casa),
      selezionata: casa == casaSelezionata,
      evidenziata: caseUltimaMossa.contains(casa),
      etichettaRiga: colonnaSchermo == 0 ? '${casa.riga + 1}' : null,
      etichettaColonna: rigaSchermo == 7 ? casa.nome[0] : null,
      onTap: () => onCasaToccata(casa),
    );
  }
}

class _CasaScacchiera extends StatelessWidget {
  const _CasaScacchiera({
    super.key,
    required this.casa,
    required this.pezzo,
    required this.selezionata,
    required this.evidenziata,
    required this.etichettaRiga,
    required this.etichettaColonna,
    required this.onTap,
  });

  final Casa casa;
  final Pezzo? pezzo;
  final bool selezionata;
  final bool evidenziata;
  final String? etichettaRiga;
  final String? etichettaColonna;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final chiara = (casa.colonna + casa.riga) % 2 == 1;
    final coloreEtichetta = chiara ? _casaScura : _casaChiara;
    final pezzo = this.pezzo;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        color: chiara ? _casaChiara : _casaScura,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (evidenziata) const ColoredBox(color: _ultimaMossa),
            if (selezionata) const ColoredBox(color: _selezione),
            if (etichettaRiga != null)
              Positioned(
                left: 2,
                top: 0,
                child: Text(etichettaRiga!, style: TextStyle(fontSize: 9, color: coloreEtichetta)),
              ),
            if (etichettaColonna != null)
              Positioned(
                right: 2,
                bottom: 0,
                child: Text(etichettaColonna!, style: TextStyle(fontSize: 9, color: coloreEtichetta)),
              ),
            if (pezzo != null)
              Padding(
                padding: const EdgeInsets.all(2),
                child: FittedBox(child: _SimboloPezzo(pezzo)),
              ),
          ],
        ),
      ),
    );
  }
}

/// Per i pezzi bianchi si sovrappongono il simbolo pieno (in bianco) e quello
/// a contorno (in nero), così restano leggibili su entrambi i colori di casa.
class _SimboloPezzo extends StatelessWidget {
  const _SimboloPezzo(this.pezzo);

  final Pezzo pezzo;

  @override
  Widget build(BuildContext context) {
    const stile = TextStyle(fontSize: 40, height: 1);
    if (pezzo.colore == ColorePezzo.nero) {
      return Text(_simboloPieno(pezzo.tipo), style: stile.copyWith(color: Colors.black));
    }
    return Stack(
      alignment: Alignment.center,
      children: [
        Text(_simboloPieno(pezzo.tipo), style: stile.copyWith(color: Colors.white)),
        Text(_simboloContorno(pezzo.tipo), style: stile.copyWith(color: Colors.black)),
      ],
    );
  }
}

/// Simboli Unicode pieni (usati per i pezzi neri e come riempimento dei bianchi).
const Map<TipoPezzo, String> _simboliPieni = {
  TipoPezzo.re: '♚',
  TipoPezzo.donna: '♛',
  TipoPezzo.torre: '♜',
  TipoPezzo.alfiere: '♝',
  TipoPezzo.cavallo: '♞',
  TipoPezzo.pedone: '♟',
};

/// Simboli Unicode a contorno (il bordo dei pezzi bianchi).
const Map<TipoPezzo, String> _simboliContorno = {
  TipoPezzo.re: '♔',
  TipoPezzo.donna: '♕',
  TipoPezzo.torre: '♖',
  TipoPezzo.alfiere: '♗',
  TipoPezzo.cavallo: '♘',
  TipoPezzo.pedone: '♙',
};

String _simboloPieno(TipoPezzo tipo) => _simboliPieni[tipo]! + _stileTesto;

String _simboloContorno(TipoPezzo tipo) => _simboliContorno[tipo]! + _stileTesto;
