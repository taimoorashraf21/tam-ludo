import 'package:material_ui/material_ui.dart';

import 'game/online_service.dart';
import 'screens/home_screen.dart';
import 'widgets/ludo_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Guarded: never throws. Without Firebase config the app still starts
  // and offline modes work fully; the Online button shows a pending state.
  await OnlineService.init();
  runApp(const TamLudoApp());
}

class TamLudoApp extends StatelessWidget {
  const TamLudoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TAM Ludo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: TamLudoTheme.primary,
        ),
        scaffoldBackgroundColor: TamLudoTheme.feltBottom,
        appBarTheme: const AppBarTheme(
          backgroundColor: TamLudoTheme.feltBottom,
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
