import 'package:material_ui/material_ui.dart';

import '../dati/lichess_api.dart';
import '../dati/puzzle_repository.dart';
import 'home.dart';
import 'puzzle.dart';

/// Schermata con la barra di navigazione in basso: Home, Puzzle e Storico.
///
/// È uno StatefulWidget perché deve ricordare la scheda selezionata.
/// IndexedStack mantiene in vita tutte le schede, così cambiando scheda
/// non si perde lo stato (ad esempio un puzzle a metà).
class SchermataPrincipale extends StatefulWidget {
  const SchermataPrincipale({
    super.key,
    required this.username,
    required this.api,
    required this.puzzleRepository,
    required this.onScollega,
  });

  final String username;
  final LichessApi api;
  final PuzzleRepository puzzleRepository;
  final VoidCallback onScollega;

  @override
  State<SchermataPrincipale> createState() => _SchermataPrincipaleState();
}

class _SchermataPrincipaleState extends State<SchermataPrincipale> {
  int _indice = 0;

  @override
  Widget build(BuildContext context) {
    final schede = [
      SchermataHome(username: widget.username, api: widget.api, onScollega: widget.onScollega),
      SchermataPuzzle(repository: widget.puzzleRepository),
      const _SchedaInArrivo(titolo: 'Storico puzzle'),
    ];
    return Scaffold(
      body: SafeArea(child: IndexedStack(index: _indice, children: schede)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indice,
        onDestinationSelected: (nuovo) => setState(() => _indice = nuovo),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.extension), label: 'Puzzle'),
          NavigationDestination(icon: Icon(Icons.history), label: 'Storico'),
        ],
      ),
    );
  }
}

/// Segnaposto temporaneo, sostituito dalla schermata vera nel prossimo passo.
class _SchedaInArrivo extends StatelessWidget {
  const _SchedaInArrivo({required this.titolo});

  final String titolo;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('$titolo in arrivo', style: Theme.of(context).textTheme.titleMedium),
    );
  }
}
