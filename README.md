# TAM Ludo

An original classic Ludo game for Android, built with Flutter. No copied
art, logo, sounds or assets from Ludo STAR or any other game — the board,
tokens, dice and icon are all drawn in code with original colours.

## Modes

- **Vs Computer** — you against 1–3 computer opponents (one fixed AI
  level: it captures when it can, prefers safe squares, brings tokens out
  on a 6, and avoids leaving tokens exposed).
- **Pass & Play** — 2–4 humans on one phone, passing the device each turn.
- **Online** — create a room and share a 6-character code, or join with a
  code. 2–4 players, synced over Firebase Realtime Database. A player who
  drops is marked away and can rejoin the same room. No turn timer.

## Rules (classic Ludo)

- 4 colours (Red, Green, Yellow, Blue), 2–4 players, 15×15 board.
- Roll a 6 to bring a token out of base. A 6 grants an extra turn; three
  6s in a row forfeits the turn (no move on the third 6).
- 8 safe cells: the 4 start cells + 4 star cells. Tokens there can't be
  captured.
- Landing on an opponent's token (non-safe cell) sends it back to base.
- An exact roll is needed to enter the centre home. First player to bring
  all 4 tokens home wins.
- No legal move → the turn passes automatically.

## Run

```bash
flutter pub get
flutter analyze        # 0 errors, 0 warnings
flutter test           # engine unit tests
flutter run            # Android device / emulator
```

Local `flutter build apk` does not work in the dev sandbox (Gradle cannot
talk to its daemon over loopback). The APK is built with GitHub Actions
(see `.github/workflows/` once the repo is created).

## Online setup

Online play needs a Firebase project. Until it is added, the app still
starts and offline modes work fully; the Online button shows
"online setup pending". See **ONLINE_SETUP.md** for the exact steps.

## Project layout

```
lib/
  main.dart                  App entry (guarded Firebase init) + theme
  game/
    ludo_engine.dart         Pure-Dart rules engine (no Flutter deps)
    ai_player.dart           Computer-opponent heuristic
    game_controller.dart     UI controller: dice, turns, AI, online sync
    online_service.dart      Firebase RTDB rooms (guarded, optional)
  screens/
    home_screen.dart         Title + mode buttons + how to play
    setup_screen.dart        Player count / names / start
    board_screen.dart        Board + dice + log + player chips
    lobby_screen.dart        Online create / join / waiting room
    game_over_screen.dart    Winner + Play Again + Home
  widgets/
    ludo_board.dart          15x15 CustomPaint board + tappable tokens
    dice_widget.dart         Dice with roll animation
    ludo_colors.dart         Original palette
test/
  ludo_engine_test.dart      Engine tests: moves, capture, safe cells,
                             three-6s forfeit, exact finish, win, geometry
```

## Originality note

Same classic Ludo rules as the genre, but every visual is original:
code-drawn board, dice and tokens, original colour palette, original
vector launcher icon. No Ludo STAR (Gameberry Labs) art, logo, name,
sounds or assets of any kind are used.
