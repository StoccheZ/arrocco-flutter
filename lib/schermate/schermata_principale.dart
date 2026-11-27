import 'package:material_ui/material_ui.dart';

/// Schermata con la barra di navigazione in basso: Home, Puzzle e Storico.
///
/// È uno StatefulWidget perché deve ricordare la scheda selezionata.
/// IndexedStack mantiene in vita tutte le schede, così cambiando scheda
/// non si perde lo stato (ad esempio un puzzle a metà).
class SchermataPrincipale extends StatefulWidget {
  const SchermataPrincipale({super.key});

  @override
  State<SchermataPrincipale> createState() => _SchermataPrincipaleState();
}

class _SchermataPrincipaleState extends State<SchermataPrincipale> {
  int _indice = 0;

  static const List<Widget> _schede = [
    _SchedaInArrivo(titolo: 'Home'),
    _SchedaInArrivo(titolo: 'Puzzle del giorno'),
    _SchedaInArrivo(titolo: 'Storico puzzle'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(index: _indice, children: _schede),
      ),
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

/// Segnaposto temporaneo, sostituito dalle schermate vere nei passi successivi.
class _SchedaInArrivo extends StatelessWidget {
  const _SchedaInArrivo({required this.titolo});

  final String titolo;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '$titolo in arrivo',
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }
}
