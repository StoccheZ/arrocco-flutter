# Arrocco – app Flutter

Versione Flutter di Arrocco, app di supporto per chi gioca a scacchi su [Lichess](https://lichess.org).
Implementa un sottoinsieme dell'[app Kotlin](https://github.com/StoccheZ/arrocco-kotlin): profilo con i rating, puzzle del giorno e storico dei puzzle.

Progetto d'esame del corso di **Programmazione Mobile**, Università Politecnica delle Marche.
Autore: **Emilio Lamberti** (matricola 1119527), progetto individuale.

## Funzionalità

- **Account**: collegamento di un account Lichess tramite username, verificato con le API pubbliche (nessuna password)
- **Home**: rating per ogni cadenza giocata con la variazione recente; aggiornamento con il pulsante o trascinando verso il basso
- **Puzzle**: puzzle del giorno di Lichess su una scacchiera interattiva, con verifica delle mosse, risposta automatica dell'avversario e soluzione
- **Storico**: puzzle affrontati con esito, percentuale di successo e serie di giorni consecutivi

Profilo e puzzle sono salvati in un database SQLite locale.

## Requisiti

- Flutter 3.50 (Dart 3.14)
- Android Studio con il plugin Flutter, oppure VS Code
- Dispositivo o emulatore Android; l'app è verificata su API 33

## Compilazione ed esecuzione

```
git clone https://github.com/StoccheZ/arrocco-flutter.git
cd arrocco-flutter
flutter pub get
flutter run
```

Per generare l'APK: `flutter build apk --release` (il file è in `build/app/outputs/flutter-apk/`).

## Struttura

| Cartella | Contenuto |
|---|---|
| `lib/dati` | Modelli, client delle API di Lichess (`http`), database SQLite (`sqflite`), repository dei puzzle |
| `lib/logica` | Logica pura: validazione dello username, FEN e mosse, risoluzione del puzzle, statistiche |
| `lib/schermate` | Onboarding, Home, Puzzle, Storico e schermata con la barra di navigazione |
| `lib/widget` | Scacchiera interattiva |
| `test` | Unit test della logica e widget test delle schermate |

Lo stato è gestito con `StatefulWidget` e `setState`; le dipendenze (API, database, repository) sono create in `main.dart` e passate ai widget tramite i costruttori.

## Librerie

`material_ui`, `http`, `sqflite`, `path`.

## Test

```
flutter test
```

Unit test di validazione, modelli, scacchi, puzzle e statistiche; widget test di onboarding, Home, puzzle e storico con un client HTTP finto (`MockClient`).

## API utilizzate

Solo endpoint pubblici di Lichess, senza autenticazione:

- `GET /api/user/{username}`
- `GET /api/puzzle/daily`
