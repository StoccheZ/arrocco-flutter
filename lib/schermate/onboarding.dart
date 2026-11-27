import 'package:material_ui/material_ui.dart';

import '../dati/lichess_api.dart';
import '../dati/modelli.dart';
import '../logica/validazione.dart';

/// Primo avvio: l'utente collega il proprio account Lichess con lo username (RF1).
class SchermataOnboarding extends StatefulWidget {
  const SchermataOnboarding({super.key, required this.api, required this.onCollegato});

  final LichessApi api;

  /// Chiamata quando lo username è stato verificato su Lichess.
  final Future<void> Function(Utente utente) onCollegato;

  @override
  State<SchermataOnboarding> createState() => _SchermataOnboardingState();
}

class _SchermataOnboardingState extends State<SchermataOnboarding> {
  final TextEditingController _username = TextEditingController();
  String? _errore;
  bool _inCaricamento = false;

  @override
  void dispose() {
    _username.dispose();
    super.dispose();
  }

  Future<void> _collega() async {
    final testo = _username.text.trim();
    final erroreFormato = validaUsername(testo);
    if (erroreFormato != null) {
      setState(() => _errore = erroreFormato);
      return;
    }
    setState(() {
      _errore = null;
      _inCaricamento = true;
    });
    try {
      final utente = await widget.api.getUtente(testo);
      await widget.onCollegato(utente);
      // Di norma la schermata viene sostituita dalla Home; se resta visibile
      // l'indicatore di caricamento non deve continuare a girare.
      if (mounted) setState(() => _inCaricamento = false);
    } on UtenteNonTrovato {
      _mostraErrore('Utente non trovato su Lichess');
    } catch (_) {
      _mostraErrore('Impossibile contattare Lichess. Controlla la connessione.');
    }
  }

  void _mostraErrore(String messaggio) {
    if (!mounted) return;
    setState(() {
      _errore = messaggio;
      _inCaricamento = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'O-O-O',
                  textAlign: TextAlign.center,
                  style: tema.textTheme.displayMedium?.copyWith(
                    color: tema.colorScheme.primary,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const SizedBox(height: 8),
                Text('Arrocco', textAlign: TextAlign.center, style: tema.textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(
                  'Collega il tuo account Lichess per seguire rating e puzzle del giorno.',
                  textAlign: TextAlign.center,
                  style: tema.textTheme.bodyMedium,
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _username,
                  enabled: !_inCaricamento,
                  autocorrect: false,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _collega(),
                  decoration: InputDecoration(
                    labelText: 'Username Lichess',
                    border: const OutlineInputBorder(),
                    errorText: _errore,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _inCaricamento ? null : _collega,
                  child: _inCaricamento
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Collega account'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
