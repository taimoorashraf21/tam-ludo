import 'package:flutter_test/flutter_test.dart';
import 'package:ludo/game/ludo_engine.dart';

LudoEngine twoPlayerEngine() => LudoEngine(players: [
      LudoPlayer(color: LudoColor.red, name: 'Red'),
      LudoPlayer(color: LudoColor.yellow, name: 'Yellow'),
    ]);

void main() {
  group('dice and leaving base', () {
    test('a token needs a 6 to leave base', () {
      final engine = twoPlayerEngine();
      expect(engine.legalMoves(0, 3), isEmpty);
      expect(engine.legalMoves(0, 5), isEmpty);
      expect(engine.legalMoves(0, 6), [0, 1, 2, 3]);
    });

    test('rolling a non-6 with all tokens in base passes the turn', () {
      final engine = twoPlayerEngine();
      final event = engine.rollWithValue(4);
      expect(event, contains('no legal move'));
      expect(engine.currentPlayer, 1);
      expect(engine.diceValue, isNull);
    });

    test('rolling a 6 brings a token out and grants an extra turn', () {
      final engine = twoPlayerEngine();
      engine.rollWithValue(6);
      expect(engine.awaitingMove, isTrue);
      final result = engine.applyMove(0);
      expect(result.fromSteps, -1);
      expect(result.toSteps, 0);
      expect(result.extraTurn, isTrue);
      expect(engine.currentPlayer, 0); // same player rolls again
    });
  });

  group('movement', () {
    test('token advances along the track', () {
      final engine = twoPlayerEngine();
      engine.rollWithValue(6);
      engine.applyMove(0);
      engine.rollWithValue(3);
      final result = engine.applyMove(0);
      expect(result.toSteps, 3);
      expect(
        LudoEngine.trackIndexFor(LudoColor.red, 3),
        3,
      );
    });

    test('token wraps around the track end', () {
      final engine = twoPlayerEngine();
      engine.players[0].tokens[0] = 50;
      engine.rollWithValue(4);
      final result = engine.applyMove(0);
      expect(result.toSteps, 54); // into the home column
      expect(LudoEngine.trackIndexFor(LudoColor.red, 54), isNull);
    });

    test('a token in the home column keeps advancing', () {
      final engine = twoPlayerEngine();
      engine.players[0].tokens[0] = 53;
      engine.rollWithValue(2);
      final result = engine.applyMove(0);
      expect(result.toSteps, 55);
    });
  });

  group('capture and safe cells', () {
    test('landing on an opponent on a normal cell captures it', () {
      final engine = twoPlayerEngine();
      // Red token at step 5 (track 5); yellow token at step 44 -> track
      // (26 + 44) % 52 = 18. Red rolls 13? No — place red so a roll of 6
      // lands exactly on 18: red at step 12, roll 6 -> step 18 (track 18).
      engine.players[0].tokens[0] = 12;
      engine.players[1].tokens[0] = 44; // yellow track index 18
      expect(LudoEngine.trackIndexFor(LudoColor.yellow, 44), 18);
      engine.rollWithValue(6);
      final result = engine.applyMove(0);
      expect(result.captured, [(1, 0)]);
      expect(engine.players[1].tokens[0], -1); // back to base
    });

    test('landing on a safe cell does NOT capture', () {
      final engine = twoPlayerEngine();
      // Star cell track index 8 is safe. Yellow at step 34 -> track
      // (26 + 34) % 52 = 8. Red at step 2, roll 6 -> step 8 (track 8).
      engine.players[1].tokens[0] = 34;
      expect(LudoEngine.trackIndexFor(LudoColor.yellow, 34), 8);
      expect(LudoEngine.safeIndices.contains(8), isTrue);
      engine.players[0].tokens[0] = 2;
      engine.rollWithValue(6);
      final result = engine.applyMove(0);
      expect(result.captured, isEmpty);
      expect(engine.players[1].tokens[0], 34); // untouched
    });

    test('start cells are safe', () {
      final engine = twoPlayerEngine();
      // Red start cell is track 0. Yellow at step 26 -> track 0.
      engine.players[1].tokens[0] = 26;
      expect(LudoEngine.trackIndexFor(LudoColor.yellow, 26), 0);
      expect(LudoEngine.safeIndices.contains(0), isTrue);
      // Red brings a token out onto its start cell (track 0).
      engine.rollWithValue(6);
      final result = engine.applyMove(0);
      expect(result.captured, isEmpty);
      expect(engine.players[1].tokens[0], 26);
    });
  });

  group('three 6s forfeit', () {
    test('third consecutive 6 forfeits the turn without moving', () {
      final engine = twoPlayerEngine();
      engine.rollWithValue(6);
      engine.applyMove(0); // extra turn
      engine.rollWithValue(6);
      engine.applyMove(1); // extra turn again
      expect(engine.consecutiveSixes, 2);
      final event = engine.rollWithValue(6);
      expect(event, contains('third 6'));
      expect(engine.awaitingMove, isFalse);
      expect(engine.currentPlayer, 1); // turn passed
      expect(engine.consecutiveSixes, 0);
      // No token moved on the third 6.
      expect(engine.players[0].tokens[2], -1);
    });

    test('a non-6 resets the six streak', () {
      final engine = twoPlayerEngine();
      engine.rollWithValue(6);
      engine.applyMove(0);
      engine.rollWithValue(4);
      expect(engine.consecutiveSixes, 0);
      engine.applyMove(0);
      expect(engine.currentPlayer, 1);
    });
  });

  group('exact roll to finish and winning', () {
    test('a token cannot overshoot home — exact roll required', () {
      final engine = twoPlayerEngine();
      engine.players[0].tokens[0] = 54;
      expect(engine.legalMoves(0, 3), isEmpty); // 54 + 3 = 57 > 56
      expect(engine.legalMoves(0, 2), [0]); // 54 + 2 = 56 exactly
    });

    test('exact roll finishes the token', () {
      final engine = twoPlayerEngine();
      engine.players[0].tokens[0] = 54;
      engine.rollWithValue(2);
      final result = engine.applyMove(0);
      expect(result.toSteps, 56);
      expect(engine.players[0].finishedCount, 1);
    });

    test('bringing all 4 tokens home wins the game', () {
      final engine = twoPlayerEngine();
      engine.players[0].tokens[0] = 56;
      engine.players[0].tokens[1] = 56;
      engine.players[0].tokens[2] = 56;
      engine.players[0].tokens[3] = 54;
      engine.rollWithValue(2);
      final result = engine.applyMove(3);
      expect(result.gameOver, isTrue);
      expect(engine.winner, LudoColor.red);
      expect(engine.isGameOver, isTrue);
    });

    test('a finished token cannot move', () {
      final engine = twoPlayerEngine();
      engine.players[0].tokens[0] = 56;
      expect(engine.legalMoves(0, 6), [1, 2, 3]);
    });
  });

  group('turn flow', () {
    test('a normal move passes the turn to the next player', () {
      final engine = twoPlayerEngine();
      engine.players[0].tokens[0] = 10;
      engine.rollWithValue(3);
      engine.applyMove(0);
      expect(engine.currentPlayer, 1);
    });

    test('capture alone does not grant an extra turn (only a 6 does)', () {
      final engine = twoPlayerEngine();
      // Red at step 15, roll 3 -> step 18 (track 18), where yellow sits.
      engine.players[0].tokens[0] = 15;
      engine.players[1].tokens[0] = 44; // yellow track index 18
      engine.rollWithValue(3);
      final result = engine.applyMove(0);
      expect(result.captured, isNotEmpty);
      expect(result.extraTurn, isFalse);
      expect(engine.currentPlayer, 1); // turn passed despite the capture
    });

    test('no legal move passes the turn automatically', () {
      final engine = twoPlayerEngine();
      // All red tokens finished except one stuck needing an exact roll.
      engine.players[0].tokens[0] = 56;
      engine.players[0].tokens[1] = 56;
      engine.players[0].tokens[2] = 56;
      engine.players[0].tokens[3] = 55; // needs exactly 1
      final event = engine.rollWithValue(4);
      expect(event, contains('no legal move'));
      expect(engine.currentPlayer, 1);
    });
  });

  group('board geometry', () {
    test('the track has 52 unique cells', () {
      expect(LudoEngine.track.length, 52);
      expect(LudoEngine.track.toSet().length, 52);
    });

    test('start cells are 13 apart', () {
      expect(LudoEngine.startIndices, [0, 13, 26, 39]);
    });

    test('there are 8 safe cells', () {
      expect(LudoEngine.safeIndices.length, 8);
    });

    test('home columns have 5 cells each', () {
      for (final c in LudoColor.values) {
        expect(LudoEngine.homeColumns[c]!.length, 5);
      }
    });

    test('every track cell is inside the 15x15 grid', () {
      for (final (r, c) in LudoEngine.track) {
        expect(r, inInclusiveRange(0, 14));
        expect(c, inInclusiveRange(0, 14));
      }
    });

    test('serialise and restore round-trips the engine', () {
      final engine = twoPlayerEngine();
      engine.rollWithValue(6);
      engine.applyMove(1);
      final json = engine.toJson();
      final restored = twoPlayerEngine();
      restored.restore(json);
      expect(restored.players[0].tokens, engine.players[0].tokens);
      expect(restored.currentPlayer, engine.currentPlayer);
      expect(restored.consecutiveSixes, engine.consecutiveSixes);
    });
  });
}
