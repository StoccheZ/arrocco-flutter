import 'package:material_ui/material_ui.dart';

import 'app.dart';
import 'dati/database.dart';
import 'dati/lichess_api.dart';

/// Punto di ingresso: crea le dipendenze una sola volta e le passa all'app.
void main() {
  runApp(ArroccoApp(api: LichessApi(), database: ArroccoDatabase()));
}
