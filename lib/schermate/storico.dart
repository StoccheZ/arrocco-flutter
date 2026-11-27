import 'package:material_ui/material_ui.dart';

import '../dati/modelli.dart';
import '../dati/puzzle_repository.dart';
import '../logica/puzzle.dart';
import '../logica/statistiche_puzzle.dart';

/// Storico dei puzzle con esito, percentuale di successo e serie di giorni (RF6).
class SchermataStorico extends StatefulWidget {
  const SchermataStorico({super.key, required this.repository});

  final PuzzleRepository repository;

  @override
  State<SchermataStorico> createState() => _SchermataStoricoState();
}

class _SchermataStoricoState extends State<SchermataStorico> {
  late Future<List<Puzzle>> _storico;

  @override
  void initState() {
    super.initState();
    _storico = widget.repository.storico();
  }

  Future<void> _ricarica() async {
    final nuovo = widget.repository.storico();
    setState(() => _storico = nuovo);
    await nuovo;
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _ricarica,
      child: FutureBuilder<List<Puzzle>>(
        future: _storico,
        builder: (context, istantanea) {
          if (istantanea.hasError) {
            return const Center(child: Text('Impossibile leggere lo storico'));
          }
          final puzzle = istantanea.data;
          if (puzzle == null) return const Center(child: CircularProgressIndicator());
          return _Contenuto(
            puzzle: puzzle,
            statistiche: calcolaStatistichePuzzle(puzzle, DateTime.now()),
          );
        },
      ),
    );
  }
}

class _Contenuto extends StatelessWidget {
  const _Contenuto({required this.puzzle, required this.statistiche});

  final List<Puzzle> puzzle;
  final StatistichePuzzle statistiche;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        Text('Storico puzzle', style: tema.textTheme.headlineSmall),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _Casella(valore: '${statistiche.affrontati}', etichetta: 'Affrontati')),
            const SizedBox(width: 8),
            Expanded(
              child: _Casella(valore: '${statistiche.percentualeSuccesso}%', etichetta: 'Successo'),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _Casella(
                valore: '${statistiche.serieAttuale}',
                etichetta: statistiche.serieAttuale == 1 ? 'Giorno di fila' : 'Giorni di fila',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Risolti al primo tentativo: ${statistiche.alPrimoColpo}',
          style: tema.textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        if (puzzle.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 24),
            child: Text(
              'Non hai ancora affrontato nessun puzzle. Inizia da quello di oggi!',
              textAlign: TextAlign.center,
            ),
          )
        else
          for (final voce in puzzle) _VocePuzzle(puzzle: voce),
      ],
    );
  }
}

class _Casella extends StatelessWidget {
  const _Casella({required this.valore, required this.etichetta});

  final String valore;
  final String etichetta;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Column(
          children: [
            Text(valore, style: tema.textTheme.titleLarge?.copyWith(color: tema.colorScheme.primary)),
            Text(etichetta, style: tema.textTheme.bodySmall, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _VocePuzzle extends StatelessWidget {
  const _VocePuzzle({required this.puzzle});

  final Puzzle puzzle;

  /// "2026-11-27" -> "27/11/2026"
  String get _data {
    final parti = puzzle.giorno.split('-');
    return parti.length == 3 ? '${parti[2]}/${parti[1]}/${parti[0]}' : puzzle.giorno;
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final (icona, colore) = switch (puzzle.esito) {
      EsitoPuzzle.risolto => (Icons.check_circle, Colors.green.shade700),
      EsitoPuzzle.risoltoConErrori => (Icons.check_circle_outline, Colors.orange.shade800),
      EsitoPuzzle.soluzioneVista => (Icons.visibility, tema.colorScheme.error),
      EsitoPuzzle.daFare => (Icons.hourglass_empty, tema.colorScheme.outline),
    };
    final dettaglio = puzzle.esito == EsitoPuzzle.risoltoConErrori
        ? '${puzzle.esito.etichetta} (${puzzle.errori})'
        : puzzle.esito.etichetta;

    return Card(
      child: ListTile(
        leading: Icon(icona, color: colore),
        title: Text('Puzzle del $_data'),
        subtitle: Text('Rating ${puzzle.rating}'),
        trailing: Text(dettaglio, style: TextStyle(color: colore)),
      ),
    );
  }
}
