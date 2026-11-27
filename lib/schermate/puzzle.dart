import 'package:material_ui/material_ui.dart';

import '../dati/modelli.dart';
import '../dati/puzzle_repository.dart';
import '../logica/puzzle.dart';
import '../logica/scacchi.dart';
import '../widget/scacchiera.dart';

/// Messaggio mostrato sopra la scacchiera.
enum _Messaggio { toccaATe, corretta, sbagliata, risolto, soluzione, giaAffrontato }

/// Puzzle del giorno da risolvere sulla scacchiera (RF3, RF4, RF5).
///
/// Lo stato è gestito con setState: lo StatoPuzzle è immutabile e ogni mossa
/// ne produce uno nuovo, come nell'app Kotlin.
class SchermataPuzzle extends StatefulWidget {
  const SchermataPuzzle({super.key, required this.repository, this.onPuzzleConcluso});

  final PuzzleRepository repository;

  /// Chiamata dopo il salvataggio dell'esito, ad esempio per aggiornare lo storico.
  final VoidCallback? onPuzzleConcluso;

  @override
  State<SchermataPuzzle> createState() => _SchermataPuzzleState();
}

class _SchermataPuzzleState extends State<SchermataPuzzle> {
  /// Pausa prima della risposta dell'avversario, per far vedere la mossa giocata.
  static const Duration _ritardoRisposta = Duration(milliseconds: 600);

  bool _caricamento = true;
  String? _errore;
  Puzzle? _puzzle;
  StatoPuzzle? _stato;
  Casa? _casaSelezionata;
  _Messaggio _messaggio = _Messaggio.toccaATe;

  /// true quando l'utente non può muovere: risposta in corso o puzzle concluso.
  bool _bloccato = false;

  @override
  void initState() {
    super.initState();
    _carica();
  }

  Future<void> _carica() async {
    setState(() {
      _caricamento = true;
      _errore = null;
    });
    try {
      final puzzle = await widget.repository.puzzleDiOggi();
      final iniziale = iniziaPuzzle(puzzle.fen, puzzle.soluzione, puzzle.ultimaMossa);
      final giaAffrontato = puzzle.esito != EsitoPuzzle.daFare;
      if (!mounted) return;
      setState(() {
        _caricamento = false;
        _puzzle = puzzle;
        // Se è già stato affrontato si mostra direttamente la posizione finale
        _stato = giaAffrontato ? iniziale.mostraSoluzione() : iniziale;
        _messaggio = giaAffrontato ? _Messaggio.giaAffrontato : _Messaggio.toccaATe;
        _bloccato = giaAffrontato;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _caricamento = false;
        _errore = 'Impossibile scaricare il puzzle. Controlla la connessione e riprova.';
      });
    }
  }

  /// Un proprio pezzo viene selezionato (o deselezionato); qualunque altra casa,
  /// con un pezzo già selezionato, diventa la destinazione della mossa.
  void _toccaCasa(Casa casa) {
    final stato = _stato;
    if (stato == null || _bloccato || stato.completato) return;

    final pezzo = stato.posizione.pezzoIn(casa);
    final selezionata = _casaSelezionata;
    if (pezzo?.colore == stato.coloreUtente) {
      setState(() => _casaSelezionata = casa == selezionata ? null : casa);
    } else if (selezionata != null) {
      _giocaMossa(stato, selezionata, casa);
    }
  }

  void _giocaMossa(StatoPuzzle stato, Casa da, Casa a) {
    final tentativo = stato.tentaMossa(da, a);
    if (!tentativo.corretto) {
      setState(() {
        _stato = tentativo.stato;
        _casaSelezionata = null;
        _messaggio = _Messaggio.sbagliata;
      });
      return;
    }

    final dopoMossa = tentativo.stato;
    if (dopoMossa.completato) {
      _concludi(dopoMossa, _Messaggio.risolto);
      return;
    }

    // Mossa giusta: si mostra, poi dopo una breve pausa risponde l'avversario
    setState(() {
      _stato = dopoMossa;
      _casaSelezionata = null;
      _messaggio = _Messaggio.corretta;
      _bloccato = true;
    });
    Future.delayed(_ritardoRisposta, () {
      if (!mounted) return;
      final dopoRisposta = dopoMossa.giocaRispostaAvversario();
      if (dopoRisposta.completato) {
        _concludi(dopoRisposta, _Messaggio.risolto);
      } else {
        setState(() {
          _stato = dopoRisposta;
          _bloccato = false;
        });
      }
    });
  }

  void _mostraSoluzione() {
    final stato = _stato;
    if (stato == null || _bloccato || stato.completato) return;
    _concludi(stato.mostraSoluzione(), _Messaggio.soluzione);
  }

  /// Mostra lo stato finale e salva esito ed errori nel database (RF6).
  Future<void> _concludi(StatoPuzzle finale, _Messaggio messaggio) async {
    final aggiornato = _puzzle?.conEsito(finale.esito, finale.errori);
    setState(() {
      _stato = finale;
      _puzzle = aggiornato;
      _casaSelezionata = null;
      _messaggio = messaggio;
      _bloccato = true;
    });
    if (aggiornato != null) {
      await widget.repository.salvaEsito(aggiornato);
      widget.onPuzzleConcluso?.call();
    }
  }

  String _testoMessaggio(StatoPuzzle stato) => switch (_messaggio) {
        _Messaggio.toccaATe => 'Muove il ${stato.coloreUtente.nome}: trova la mossa migliore',
        _Messaggio.corretta => 'Mossa corretta! Continua',
        _Messaggio.sbagliata => 'Mossa sbagliata, riprova',
        _Messaggio.risolto => switch (stato.errori) {
            0 => 'Puzzle risolto al primo tentativo!',
            1 => 'Puzzle risolto con 1 errore',
            final n => 'Puzzle risolto con $n errori',
          },
        _Messaggio.soluzione => 'Ecco la soluzione. Ritenta domani!',
        _Messaggio.giaAffrontato => 'Hai già affrontato il puzzle di oggi. Torna domani!',
      };

  Color _coloreMessaggio(ThemeData tema) => switch (_messaggio) {
        _Messaggio.corretta || _Messaggio.risolto => Colors.green.shade700,
        _Messaggio.sbagliata => tema.colorScheme.error,
        _ => tema.colorScheme.onSurface,
      };

  @override
  Widget build(BuildContext context) {
    if (_caricamento) return const Center(child: CircularProgressIndicator());

    final stato = _stato;
    final puzzle = _puzzle;
    if (stato == null || puzzle == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_errore ?? 'Puzzle non disponibile', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: _carica, child: const Text('Riprova')),
            ],
          ),
        ),
      );
    }

    final tema = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Puzzle del giorno', style: tema.textTheme.headlineSmall),
          Text('Rating ${puzzle.rating}', style: tema.textTheme.bodySmall),
          const SizedBox(height: 12),
          Text(
            _testoMessaggio(stato),
            style: tema.textTheme.titleMedium?.copyWith(color: _coloreMessaggio(tema)),
          ),
          const SizedBox(height: 12),
          Scacchiera(
            posizione: stato.posizione,
            orientamento: stato.coloreUtente,
            casaSelezionata: _casaSelezionata,
            ultimaMossa: stato.ultimaMossa,
            onCasaToccata: _toccaCasa,
          ),
          const SizedBox(height: 12),
          Text('Errori: ${stato.errori}', style: tema.textTheme.bodyMedium),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: (_bloccato || stato.completato) ? null : _mostraSoluzione,
            child: const Text('Mostra soluzione'),
          ),
        ],
      ),
    );
  }
}
