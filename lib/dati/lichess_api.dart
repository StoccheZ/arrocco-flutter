import 'dart:convert';

import 'package:http/http.dart' as http;

import 'modelli.dart';

/// Lanciata quando lo username non esiste su Lichess (risposta 404).
class UtenteNonTrovato implements Exception {
  const UtenteNonTrovato(this.username);

  final String username;

  @override
  String toString() => 'Utente "$username" non trovato su Lichess';
}

/// Accesso alle API pubbliche di Lichess con il package http.
///
/// Il client si può passare dall'esterno: nei test si usa un MockClient
/// che restituisce risposte preparate, senza andare in rete.
class LichessApi {
  LichessApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const String _indirizzoBase = 'https://lichess.org';

  /// Lichess chiede alle applicazioni di identificarsi con uno User-Agent.
  static const Map<String, String> _intestazioni = {
    'User-Agent': 'Arrocco-Flutter/1.0 (progetto universitario UNIVPM)',
    'Accept': 'application/json',
  };

  static const Duration _attesaMassima = Duration(seconds: 15);

  /// Profilo e rating di un utente (RF1, RF2).
  Future<Utente> getUtente(String username) async {
    final indirizzo = Uri.parse('$_indirizzoBase/api/user/${Uri.encodeComponent(username)}');
    final risposta = await _client.get(indirizzo, headers: _intestazioni).timeout(_attesaMassima);
    if (risposta.statusCode == 404) throw UtenteNonTrovato(username);
    if (risposta.statusCode != 200) {
      throw http.ClientException('Risposta inattesa da Lichess: ${risposta.statusCode}', indirizzo);
    }
    final json = jsonDecode(utf8.decode(risposta.bodyBytes)) as Map<String, dynamic>;
    return Utente.fromJson(json);
  }

  /// Puzzle del giorno di Lichess, associato al [giorno] indicato (RF3).
  Future<Puzzle> getPuzzleDelGiorno(String giorno) async {
    final indirizzo = Uri.parse('$_indirizzoBase/api/puzzle/daily');
    final risposta = await _client.get(indirizzo, headers: _intestazioni).timeout(_attesaMassima);
    if (risposta.statusCode != 200) {
      throw http.ClientException('Risposta inattesa da Lichess: ${risposta.statusCode}', indirizzo);
    }
    final json = jsonDecode(utf8.decode(risposta.bodyBytes)) as Map<String, dynamic>;
    return Puzzle.daJsonDelGiorno(json, giorno);
  }
}
