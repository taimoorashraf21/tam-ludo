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

/// App-wide theme colours.
class TamLudoTheme {
  static const Color background = Color(0xFFFFF6E5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color primary = Color(0xFF0F766E);
  static const Color primaryDark = Color(0xFF0B5953);
  static const Color ink = Color(0xFF263238);
  static const Color muted = Color(0xFF78909C);
  static const Color boardLine = Color(0xFFB0BEC5);
}
