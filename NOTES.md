# TAM Ludo — build notes (for the parent agent)

## What was built

Complete Flutter source for **TAM Ludo** (package `com.tam.ludo`, app
name "TAM Ludo"), an original classic Ludo game. No Ludo STAR art, logo,
name, sounds or assets — board, dice, tokens and launcher icon are all
drawn in code with an original colour palette.

Working directory: `~/workspace/tam-ludo/` — local git repo, 1 commit
(`22ac468` + follow-ups; run `git log` for the current head).

## File list

```
pubspec.yaml                 firebase_core + firebase_database added
lib/main.dart                Guarded Firebase init + Material 3 theme
lib/game/ludo_engine.dart    Pure-Dart rules engine (52-cell track, home
                             columns, capture, safe cells, 3x6 forfeit,
                             exact-roll finish, win, toJson/restore)
lib/game/ai_player.dart      Heuristic: capture > safe cell > leave base
                             > furthest token, minus exposure penalty
lib/game/game_controller.dart  Dice animation state, turn flow, AI
                             automation, online RTDB sync, away pass-turn
lib/game/online_service.dart   Firebase RTDB rooms (guarded init)
lib/screens/home_screen.dart    Modes + how to play
lib/screens/setup_screen.dart  Player count 2-4, names, Start
lib/screens/board_screen.dart   Banner + board + dice + log + chips
lib/screens/lobby_screen.dart   Online create/join/waiting room
lib/screens/game_over_screen.dart  Winner + Play Again + Home
lib/widgets/ludo_board.dart     15x15 CustomPaint board + tappable tokens
lib/widgets/dice_widget.dart    Dice with roll animation
lib/widgets/ludo_colors.dart    Original palette
android/.../drawable/ic_launcher.xml  Original vector icon (4 tokens)
android/.../AndroidManifest.xml       Label "TAM Ludo", icon -> drawable
test/ludo_engine_test.dart   24 engine tests
README.md / ONLINE_SETUP.md / NOTES.md (this file)
```

## Verification (done in this sandbox)

- `flutter analyze`: **No issues found** (0 errors, 0 warnings, 0 infos).
- `flutter test`: **24/24 passed** — dice/base rules, movement, capture,
  safe cells, three-6s forfeit, exact-roll finish, win detection, turn
  flow, board geometry (52 unique cells, 8 safe cells), serialise/restore.
- `flutter build web` (JS, `--no-web-resources-cdn`): built; home screen
  + board verified by headless-Chromium screenshots (see `~/workspace/
  tam-ludo/` — shots were taken in /tmp during verification).
- `flutter build apk`: **NOT attempted locally on purpose** — this
  sandbox intercepts Java loopback TCP so Gradle can never talk to its
  daemon (verified 6x on ServiceTrail). The APK must be built via
  GitHub Actions (see below).

## What the parent still has to do

1. **GitHub repo + Actions APK build** (same route as ServiceTrail):
   create repo `taimoorashraf21/tam-ludo` (browser, since the connector
   cannot create repos), push this source (per-file Contents API or
   browser web-UI upload; bulk push_files is 403), add
   `.github/workflows/build-apk.yml` via the browser web UI (workflow
   files are 403 via connector), run it, download the artifact, verify
   the APK (package `com.tam.ludo`, signed v2/v3) and deliver it.
   Suggested workflow: Flutter 3.50.0, `flutter pub get` →
   `flutter analyze` → `flutter build apk --debug` → upload artifact.
2. **Firebase (online play)** — only if online is wanted now: follow
   `ONLINE_SETUP.md` (create project, Realtime Database, add
   `android/app/google-services.json`, add the `com.google.gms.
   google-services` plugin lines). Until then the app starts fine and
   offline modes work; the Online button shows "online setup pending".
3. **On-device check** (after the APK is delivered): install on the
   phone, play one Vs Computer game end-to-end (dice tap, token tap,
   capture, finish) and one Pass & Play game — the board was verified
   in a headless browser only, not on a real phone yet.

## Known limitations / honest notes

- Online play is **code-complete but untested against a live Firebase
  project** (no google-services.json exists yet). The sync design is
  single-writer (only the player whose turn it is pushes state), rooms
  are keyed by a 6-character code, drops are marked away via
  onDisconnect and can rejoin by name; an "away player pass turn"
  button prevents a stuck game. Test it live once Firebase is set up.
- **Firebase init hang (web only, fixed):** on web, `Firebase.
  initializeApp()` dynamically imports the Firebase JS SDK from the
  gstatic CDN; if that fetch hangs, the import's promise never settles
  and init would hang forever. `OnlineService.init()` now has an 8s
  timeout, so the app always boots with online disabled instead. On
  Android this cannot happen (native SDK, no CDN fetch) — it throws
  fast when unconfigured.
- AI is one fixed difficulty (no easy/hard levels — per the brief).
- No turn timer online (per the brief).
- Capture rule: landing on a non-safe cell captures ALL opponent tokens
  on that cell (simple classic rule; no 2-token block rule).
- The web build in `build/` is a verification artefact only, not a
  deliverable; the APK is the deliverable.
