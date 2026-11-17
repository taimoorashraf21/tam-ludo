import 'package:material_ui/material_ui.dart';

import '../game/ludo_engine.dart';

/// Original TAM Ludo palette (plain colours — no copied art or assets).
const Map<LudoColor, Color> ludoColors = {
  LudoColor.red: Color(0xFFE53935),
  LudoColor.green: Color(0xFF43A047),
  LudoColor.yellow: Color(0xFFF9C80E),
  LudoColor.blue: Color(0xFF1E88E5),
};

/// Darker shade of each colour, for token borders and text on light fills.
const Map<LudoColor, Color> ludoDarkColors = {
  LudoColor.red: Color(0xFFB71C1C),
  LudoColor.green: Color(0xFF1B5E20),
  LudoColor.yellow: Color(0xFFF57F17),
  LudoColor.blue: Color(0xFF0D47A1),
};

/// Lighter shade of each colour, for gradients and highlights.
const Map<LudoColor, Color> ludoLightColors = {
  LudoColor.red: Color(0xFFEF5350),
  LudoColor.green: Color(0xFF66BB6A),
  LudoColor.yellow: Color(0xFFFFD54F),
  LudoColor.blue: Color(0xFF42A5F5),
};

/// App-wide theme colours: a rich green "felt table" look with gold accents.
/// Everything is code-drawn; no images or copied artwork.
class TamLudoTheme {
  // Felt table background.
  static const Color feltTop = Color(0xFF10603F);
  static const Color feltMid = Color(0xFF0B4A30);
  static const Color feltBottom = Color(0xFF062E1D);
  static const Color feltGlow = Color(0xFF1B7A4D);

  // Gold accents (buttons, rims, highlights).
  static const Color gold = Color(0xFFFFC93C);
  static const Color goldDark = Color(0xFFD9930D);
  static const Color goldLight = Color(0xFFFFE082);

  // Cards and text.
  static const Color creamCard = Color(0xFFFFF8E7);
  static const Color cardShadow = Color(0x66000000);

  // Board frame: a warm wood-brown rim around the white board.
  static const Color boardFrame = Color(0xFF7A4E1D);
  static const Color boardFrameLight = Color(0xFFB07A35);
  static const Color boardFrameDark = Color(0xFF4E2F0E);

  // Legacy fields (kept so older widgets keep compiling).
  static const Color background = Color(0xFF062E1D);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color primary = Color(0xFF0F766E);
  static const Color primaryDark = Color(0xFF0B5953);
  static const Color ink = Color(0xFF263238);
  static const Color muted = Color(0xFF78909C);
  static const Color boardLine = Color(0xFF94A3B8);
}
