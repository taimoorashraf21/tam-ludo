import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../game/game_controller.dart';
import '../game/ludo_engine.dart';
import '../game/online_service.dart';
import '../widgets/game_widgets.dart';
import '../widgets/ludo_colors.dart';
import 'board_screen.dart';

/// Online lobby: create a room (get a 6-character code) or join with one.
/// Shows the player list live; the host starts when 2+ players are in.
class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  final _nameController = TextEditingController(text: 'Player 1');
  final _codeController = TextEditingController();

  String? _roomCode;
  String? _myUid;
  LudoColor? _myColor;
  bool _isHost = false;
  bool _busy = false;

  RoomSnapshot? _room;
  StreamSubscription<RoomSnapshot?>? _roomSub;
  bool _navigatedToBoard = false;

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _roomSub?.cancel();
    super.dispose();
  }

  String get _myName {
    final name = _nameController.text.trim();
    return name.isEmpty ? 'Player 1' : name;
  }

  Future<void> _createRoom() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final uid = OnlineService.generateUid();
      final code = await OnlineService.createRoom(
        hostUid: uid,
        hostName: _myName,
        hostColor: LudoColor.red,
      );
      setState(() {
        _roomCode = code;
        _myUid = uid;
        _myColor = LudoColor.red;
        _isHost = true;
        _busy = false;
      });
      _subscribe(code);
    } catch (e) {
      setState(() => _busy = false);
      _showError('Could not create a room: $e');
    }
  }

  Future<void> _joinRoom() async {
    if (_busy) return;
    final code = _codeController.text.trim().toUpperCase();
    if (code.length != 6) {
      _showError('Enter the 6-character room code.');
      return;
    }
    setState(() => _busy = true);
    try {
      final uid = OnlineService.generateUid();
      final snap = await OnlineService.joinRoom(
        code: code,
        uid: uid,
        name: _myName,
      );
      if (snap == null) {
        setState(() => _busy = false);
        _showError('No room with code $code. Check the code and try again.');
        return;
      }
      final me = snap.players.firstWhere((p) => p.uid == uid);
      setState(() {
        _roomCode = code;
        _myUid = uid;
        _myColor = me.color;
        _isHost = false;
        _busy = false;
      });
      _subscribe(code);
    } catch (e) {
      setState(() => _busy = false);
      _showError('Could not join: $e');
    }
  }

  void _subscribe(String code) {
    _roomSub?.cancel();
    _roomSub = OnlineService.watchRoom(code).listen((snap) {
      if (!mounted || snap == null) return;
      setState(() => _room = snap);
      if (snap.isPlaying && !_navigatedToBoard) {
        _navigatedToBoard = true;
        _enterGame(snap);
      }
    });
  }

  void _enterGame(RoomSnapshot snap) {
    final players = snap.players.toList()
      ..sort((a, b) => a.color.index.compareTo(b.color.index));
    final enginePlayers = players
        .map((p) => LudoPlayer(color: p.color, name: p.name))
        .toList();
    final controller = GameController(
      mode: GameMode.online,
      players: enginePlayers,
      roomCode: snap.code,
      myUid: _myUid,
      myColor: _myColor,
      isHost: _isHost,
    );
    if (snap.engineJson != null) {
      controller.engine.restore(snap.engineJson!);
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => BoardScreen(controller: controller),
      ),
    );
  }

  Future<void> _startGame() async {
    final room = _room;
    final code = _roomCode;
    if (room == null || code == null || room.players.length < 2) return;
    setState(() => _busy = true);
    try {
      final players = room.players.toList()
        ..sort((a, b) => a.color.index.compareTo(b.color.index));
      final engine = LudoEngine(
        players: players
            .map((p) => LudoPlayer(color: p.color, name: p.name))
            .toList(),
      );
      await OnlineService.startGame(code, engine);
    } catch (e) {
      setState(() => _busy = false);
      _showError('Could not start the game: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_roomCode == null) return _buildEntry(context);
    return _buildWaitingRoom(context);
  }

  // ------------------------------------------------------------ entry

  Widget _buildEntry(BuildContext context) {
    return Scaffold(
      backgroundColor: TamLudoTheme.feltBottom,
      appBar: AppBar(
        backgroundColor: TamLudoTheme.feltBottom,
        foregroundColor: Colors.white,
        title: const Text('Online', style: TextStyle(fontWeight: FontWeight.w900)),
        centerTitle: true,
      ),
      body: FeltBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Your name',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: TamLudoTheme.creamCard,
                      ),
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      'Create a room',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: TamLudoTheme.ink,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Share the 6-character code with 1–3 friends. '
                      'You start the game when everyone is in.',
                      style: TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 12),
                    GoldButton(
                      label: 'CREATE ROOM',
                      icon: Icons.add_circle,
                      enabled: !_busy,
                      onTap: _createRoom,
                    ),
                    const SizedBox(height: 24),
                    const Row(
                      children: [
                        Expanded(child: Divider()),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            'OR',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black45,
                            ),
                          ),
                        ),
                        Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Join a room',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: TamLudoTheme.ink,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _codeController,
                      textCapitalization: TextCapitalization.characters,
                      maxLength: 6,
                      decoration: const InputDecoration(
                        labelText: 'Room code (6 characters)',
                        border: OutlineInputBorder(),
                        counterText: '',
                        filled: true,
                        fillColor: TamLudoTheme.creamCard,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _busy ? null : _joinRoom,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E88E5),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Join Room',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_busy) ...[
                const SizedBox(height: 20),
                const Center(
                  child: CircularProgressIndicator(color: TamLudoTheme.gold),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------ waiting room

  Widget _buildWaitingRoom(BuildContext context) {
    final room = _room;
    final players = room?.players ?? const <RoomPlayer>[];
    final canStart = _isHost && players.length >= 2 && room?.status == 'waiting';
    return Scaffold(
      backgroundColor: TamLudoTheme.feltBottom,
      appBar: AppBar(
        backgroundColor: TamLudoTheme.feltBottom,
        foregroundColor: Colors.white,
        title: const Text(
          'Online Lobby',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        centerTitle: true,
      ),
      body: FeltBackground(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: TamLudoTheme.gold.withValues(alpha: 0.7),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Room code',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15, color: Colors.white70),
                    ),
                    Text(
                      _roomCode ?? '',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 8,
                        color: TamLudoTheme.gold,
                      ),
                    ),
                    const Text(
                      'Share this code with your friends.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Players',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              for (final p in players) _playerTile(p),
              const SizedBox(height: 24),
              if (_isHost)
                GoldButton(
                  label: players.length < 2
                      ? 'WAITING FOR PLAYERS…'
                      : 'START GAME',
                  icon: Icons.play_arrow,
                  enabled: canStart && !_busy,
                  onTap: _startGame,
                )
              else
                const Text(
                  'Waiting for the host to start the game…',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _playerTile(RoomPlayer p) {
    final isMe = p.uid == _myUid;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: PlayerAvatar(color: p.color, name: p.name, size: 38),
        title: Text('${p.name}${isMe ? ' (you)' : ''}'),
        subtitle: Text(p.color.label),
        trailing: Icon(
          p.connected ? Icons.circle : Icons.circle_outlined,
          size: 14,
          color: p.connected ? Colors.green : Colors.grey,
        ),
      ),
    );
  }
}
