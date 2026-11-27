import 'package:material_ui/material_ui.dart';

import 'schermate/schermata_principale.dart';

/// Viola del logo O-O-O, lo stesso dell'app Kotlin.
const Color violaArrocco = Color(0xFF8B5CF6);

/// Widget radice: tema chiaro e scuro (segue il sistema) e schermata iniziale.
class ArroccoApp extends StatelessWidget {
  const ArroccoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Arrocco',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: violaArrocco),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: violaArrocco,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.system,
      home: const SchermataPrincipale(),
    );
  }
}
