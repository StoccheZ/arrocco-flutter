import 'package:material_ui/material_ui.dart';

import 'dati/database.dart';
import 'dati/lichess_api.dart';
import 'dati/modelli.dart';
import 'dati/puzzle_repository.dart';
import 'schermate/onboarding.dart';
import 'schermate/schermata_principale.dart';

/// Viola del logo O-O-O, lo stesso dell'app Kotlin.
const Color violaArrocco = Color(0xFF8B5CF6);

/// Widget radice: tema chiaro e scuro (segue il sistema) e schermata iniziale.
class ArroccoApp extends StatelessWidget {
  const ArroccoApp({super.key, required this.api, required this.database});

  final LichessApi api;
  final ArroccoDatabase database;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Arrocco',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: violaArrocco)),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: violaArrocco, brightness: Brightness.dark),
      ),
      themeMode: ThemeMode.system,
      home: _Avvio(api: api, database: database),
    );
  }
}

/// Decide cosa mostrare all'avvio: onboarding se non c'è un account collegato,
/// altrimenti la schermata principale.
class _Avvio extends StatefulWidget {
  const _Avvio({required this.api, required this.database});

  final LichessApi api;
  final ArroccoDatabase database;

  @override
  State<_Avvio> createState() => _AvvioState();
}

class _AvvioState extends State<_Avvio> {
  late final PuzzleRepository _puzzleRepository =
      PuzzleRepository(api: widget.api, database: widget.database);
  bool _caricato = false;
  String? _username;

  @override
  void initState() {
    super.initState();
    _caricaProfilo();
  }

  Future<void> _caricaProfilo() async {
    final username = await widget.database.leggiUsername();
    if (!mounted) return;
    setState(() {
      _username = username;
      _caricato = true;
    });
  }

  Future<void> _collegato(Utente utente) async {
    await widget.database.salvaProfilo(utente.id, utente.username);
    if (!mounted) return;
    setState(() => _username = utente.id);
  }

  Future<void> _scollega() async {
    await widget.database.eliminaProfilo();
    if (!mounted) return;
    setState(() => _username = null);
  }

  @override
  Widget build(BuildContext context) {
    if (!_caricato) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final username = _username;
    if (username == null) {
      return SchermataOnboarding(api: widget.api, onCollegato: _collegato);
    }
    return SchermataPrincipale(
      username: username,
      api: widget.api,
      puzzleRepository: _puzzleRepository,
      onScollega: _scollega,
    );
  }
}
