import 'ludo_engine.dart';

/// Single-level computer opponent.
///
/// Move choice, in priority order:
///   1. Capture an opponent token.
///   2. Land on a safe cell.
///   3. Bring a token out of base (on a 6).
///   4. Move the furthest-advanced token.
///   5. Avoid leaving a token exposed to capture when a safer move exists
///      (a token on a non-safe cell with an opponent 1-6 steps behind it
///      is penalised).
///
/// Implemented as a score over a simulated copy of the engine, so the
/// priorities above fall out of the weights.
class AiPlayer {
  /// Pick the token index the AI should move. The engine must already have
  /// a dice value rolled ([LudoEngine.awaitingMove] true).
  static int chooseMove(LudoEngine engine, int playerIndex) {
    final dice = engine.diceValue;
    if (dice == null) {
      throw StateError('AI asked to move before the dice was rolled.');
    }
    final moves = engine.legalMoves(playerIndex, dice);
    if (moves.isEmpty) {
      throw StateError('AI asked to move but has no legal move.');
    }
    var bestMove = moves.first;
    var bestScore = double.negativeInfinity;
    for (final move in moves) {
      final score = _scoreMove(engine, playerIndex, move);
      if (score > bestScore) {
        bestScore = score;
        bestMove = move;
      }
    }
    return bestMove;
  }

  static double _scoreMove(LudoEngine engine, int playerIndex, int move) {
    final player = engine.players[playerIndex];
    final fromSteps = player.tokens[move];

    // Simulate the move on a copy to see captures / finish / extra turn.
    final sim = engine.clone();
    sim.currentPlayer = playerIndex;
    final result = sim.applyMove(move);

    var score = 0.0;
    // 1. Capture is the best outcome.
    score += result.captured.length * 100.0;
    // Finishing a token is almost as good.
    if (result.toSteps == LudoEngine.finishSteps) score += 60.0;
    // 2. Landing on a safe cell.
    final landing = LudoEngine.trackIndexFor(player.color, result.toSteps);
    if (landing != null && LudoEngine.safeIndices.contains(landing)) {
      score += 50.0;
    }
    // 3. Bringing a token out of base.
    if (fromSteps == -1) score += 40.0;
    // 4. Prefer the furthest-advanced token (breaks ties towards progress).
    score += result.toSteps * 1.0;
    // Extra turn on a 6 is a small bonus.
    if (result.extraTurn) score += 10.0;
    // 5. Exposure penalty: landing on a non-safe cell while an opponent
    // token sits 1-6 track steps behind the landing cell means the token
    // can be captured next turn.
    if (landing != null && !LudoEngine.safeIndices.contains(landing)) {
      if (_isExposed(sim, playerIndex, landing)) score -= 30.0;
    }
    // Small nudge: leaving base on a 6 is good, but don't waste a 6
    // bringing a token out when a capture is available (handled by weights).
    return score;
  }

  /// True when any opponent token is 1-6 track steps behind [landingIndex]
  /// (i.e. it could capture a token standing there on its next roll).
  static bool _isExposed(LudoEngine engine, int playerIndex, int landing) {
    for (var pi = 0; pi < engine.players.length; pi++) {
      if (pi == playerIndex) continue;
      final other = engine.players[pi];
      for (final steps in other.tokens) {
        final idx = LudoEngine.trackIndexFor(other.color, steps);
        if (idx == null) continue;
        final behind = (landing - idx) % LudoEngine.trackLength;
        if (behind >= 1 && behind <= 6) return true;
      }
    }
    return false;
  }
}
