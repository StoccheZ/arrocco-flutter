/// Username Lichess: da 2 a 30 caratteri tra lettere, numeri, "_" e "-",
/// con una lettera o un numero all'inizio (stesse regole dell'app Kotlin).
final RegExp _formatoUsername = RegExp(r'^[A-Za-z0-9][A-Za-z0-9_-]{1,29}$');

/// Controlla il formato dello username prima di contattare Lichess.
///
/// Restituisce il messaggio di errore da mostrare, oppure null se è valido.
String? validaUsername(String username) {
  if (username.trim().isEmpty) return 'Inserisci il tuo username Lichess';
  if (username.length < 2 || username.length > 30) {
    return 'Lo username deve avere tra 2 e 30 caratteri';
  }
  if (!_formatoUsername.hasMatch(username)) return 'Usa solo lettere, numeri, _ e -';
  return null;
}
