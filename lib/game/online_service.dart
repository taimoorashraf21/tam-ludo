import 'dart:async';
import 'dart:math';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

import 'ludo_engine.dart';

/// Online play over Firebase Realtime Database (free Spark tier).
///
/// IMPORTANT: Firebase is optional. [init] never throws — if the app has no
/// Firebase configuration yet (no google-services.json / no web config),
/// [isConfigured] stays false and the app runs fully offline. The Online
/// button then shows an "online setup pending" state instead of crashing.
/// See ONLINE_SETUP.md for what the parent must add to enable online play.
///
/// Room layout (one node per room, under `rooms/CODE`):
///   {
///     "status": "waiting" | "playing" | "finished",
///     "hostUid": "...",
///     "revision": 123456789,        // ms epoch of the last state push
///     "engine": { ...LudoEngine.toJson()... },
///     "log": ["...", "..."],
///     "players": { "UID": {
///         "name": "...", "color": 0, "connected": true } }
///   }
///
/// Only the player whose turn it is writes moves (roll / move). Everyone
/// listens to the room and mirrors the engine state. A player who drops is
/// marked away (onDisconnect) and can rejoin the same room by name.
class OnlineService {
  OnlineService._();

  static bool _configured = false;

  /// True once Firebase initialised successfully.
  static bool get isConfigured => _configured;

  /// Guarded initialisation: never throws and never hangs. Call once
  /// from main(). On web, the Firebase JS SDK is fetched from a CDN at
  /// init time; if that fetch hangs (offline / blocked network) the
  /// timeout below lets the app start anyway with online disabled.
  static Future<bool> init() async {
    if (_configured) return true;
    try {
      await Firebase.initializeApp()
          .timeout(const Duration(seconds: 8));
      // A cheap read proves the database is actually reachable.
      _database = FirebaseDatabase.instance;
      _configured = true;
    } catch (_) {
      _configured = false;
    }
    return _configured;
  }

  static FirebaseDatabase? _database;

  static FirebaseDatabase get _db {
    final db = _database;
    if (db == null || !_configured) {
      throw StateError('Firebase is not configured (see ONLINE_SETUP.md).');
    }
    return db;
  }

  /// 6-character room code: uppercase letters + digits, no look-alikes.
  static String generateCode() {
    const chars = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
    final r = Random();
    return List.generate(6, (_) => chars[r.nextInt(chars.length)]).join();
  }

  static String generateUid() {
    final r = Random();
    final stamp = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    final rand = r.nextInt(1 << 30).toRadixString(36);
    return 'u$stamp$rand';
  }

  static DatabaseReference _roomRef(String code) =>
      _db.ref('rooms/$code');

  /// Create a room as host. Returns the room code.
  static Future<String> createRoom({
    required String hostUid,
    required String hostName,
    required LudoColor hostColor,
  }) async {
    final code = generateCode();
    final ref = _roomRef(code);
    await ref.set({
      'status': 'waiting',
      'hostUid': hostUid,
      'revision': DateTime.now().millisecondsSinceEpoch,
      'engine': null,
      'log': <String>[],
      'players': {
        hostUid: {
          'name': hostName,
          'color': hostColor.index,
          'connected': true,
        },
      },
    });
    // Mark the host away automatically if they disconnect.
    await ref.child('players/$hostUid/connected').onDisconnect().set(false);
    return code;
  }

  /// Join a room. Returns null when the code does not exist.
  /// If a disconnected player with the same name is already in the room,
  /// their slot is reclaimed (reconnect).
  static Future<RoomSnapshot?> joinRoom({
    required String code,
    required String uid,
    required String name,
  }) async {
    final ref = _roomRef(code);
    final snap = await ref.get();
    if (!snap.exists) return null;
    final data = Map<String, dynamic>.from(snap.value as Map);
    final players =
        Map<String, dynamic>.from(data['players'] as Map? ?? {});

    // Reconnect: reclaim an away slot with the same name.
    String? reclaimUid;
    for (final entry in players.entries) {
      final p = Map<String, dynamic>.from(entry.value as Map);
      if (p['name'] == name && p['connected'] != true) {
        reclaimUid = entry.key;
        break;
      }
    }
    if (reclaimUid != null) {
      await ref.child('players/$reclaimUid').update({
        'connected': true,
      });
      await ref
          .child('players/$reclaimUid/connected')
          .onDisconnect()
          .set(false);
      // Move the slot to the new uid so future writes use it.
      final slot = Map<String, dynamic>.from(players[reclaimUid] as Map);
      await ref.child('players/$uid').set(slot);
      await ref.child('players/$reclaimUid').remove();
      await ref
          .child('players/$uid/connected')
          .onDisconnect()
          .set(false);
    } else {
      if (players.length >= 4) {
        throw StateError('Room is full (4 players max).');
      }
      final usedColors = players.values
          .map((p) =>
              (Map<String, dynamic>.from(p as Map)['color'] as num).toInt())
          .toSet();
      final freeColor = LudoColor.values
          .firstWhere((c) => !usedColors.contains(c.index));
      await ref.child('players/$uid').set({
        'name': name,
        'color': freeColor.index,
        'connected': true,
      });
      await ref
          .child('players/$uid/connected')
          .onDisconnect()
          .set(false);
    }
    return RoomSnapshot.fromData(code, await _readRoom(ref));
  }

  static Future<Map<String, dynamic>> _readRoom(DatabaseReference ref) async {
    final snap = await ref.get();
    return Map<String, dynamic>.from(snap.value as Map);
  }

  /// Live stream of room snapshots (null while the room is deleted).
  static Stream<RoomSnapshot?> watchRoom(String code) {
    return _roomRef(code).onValue.map((event) {
      if (!event.snapshot.exists) return null;
      return RoomSnapshot.fromData(
        code,
        Map<String, dynamic>.from(event.snapshot.value as Map),
      );
    });
  }

  /// Host starts the game once 2+ players have joined.
  static Future<void> startGame(String code, LudoEngine engine) async {
    final ref = _roomRef(code);
    await ref.update({
      'status': 'playing',
      'revision': DateTime.now().millisecondsSinceEpoch,
      'engine': engine.toJson(),
      'log': ['Game started.'],
    });
  }

  /// Push the whole engine state after a local roll / move.
  static Future<void> pushState(
    String code,
    LudoEngine engine,
    List<String> log,
  ) async {
    final ref = _roomRef(code);
    await ref.update({
      'revision': DateTime.now().millisecondsSinceEpoch,
      'engine': engine.toJson(),
      'log': log,
    });
  }

  /// Mark the game finished (winner set in the engine state).
  static Future<void> finishGame(String code) async {
    await _roomRef(code).update({'status': 'finished'});
  }

  /// Leave a room (marks this player away; the room stays for the others).
  static Future<void> leaveRoom(String code, String uid) async {
    try {
      await _roomRef(code).child('players/$uid/connected').set(false);
    } catch (_) {
      // Leaving must never crash the app, even if offline.
    }
  }
}

/// A parsed snapshot of a room.
class RoomSnapshot {
  RoomSnapshot({
    required this.code,
    required this.status,
    required this.hostUid,
    required this.revision,
    required this.engineJson,
    required this.log,
    required this.players,
  });

  factory RoomSnapshot.fromData(
      String code, Map<String, dynamic> data) {
    final players = <RoomPlayer>[];
    final rawPlayers = Map<String, dynamic>.from(
        data['players'] as Map? ?? {});
    for (final entry in rawPlayers.entries) {
      final p = Map<String, dynamic>.from(entry.value as Map);
      players.add(RoomPlayer(
        uid: entry.key,
        name: p['name'] as String? ?? 'Player',
        color: LudoColor.values[(p['color'] as num?)?.toInt() ?? 0],
        connected: p['connected'] as bool? ?? false,
      ));
    }
    return RoomSnapshot(
      code: code,
      status: data['status'] as String? ?? 'waiting',
      hostUid: data['hostUid'] as String? ?? '',
      revision: (data['revision'] as num?)?.toInt() ?? 0,
      engineJson: data['engine'] == null
          ? null
          : Map<String, dynamic>.from(data['engine'] as Map),
      log: (data['log'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          <String>[],
      players: players,
    );
  }

  final String code;
  final String status; // waiting | playing | finished
  final String hostUid;
  final int revision;
  final Map<String, dynamic>? engineJson;
  final List<String> log;
  final List<RoomPlayer> players;

  bool get isPlaying => status == 'playing';
  bool get isFinished => status == 'finished';
}

class RoomPlayer {
  const RoomPlayer({
    required this.uid,
    required this.name,
    required this.color,
    required this.connected,
  });

  final String uid;
  final String name;
  final LudoColor color;
  final bool connected;
}
