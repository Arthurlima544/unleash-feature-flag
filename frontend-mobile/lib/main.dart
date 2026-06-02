import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/feature_flag_service.dart';
import 'core/feature_flag_model.dart';
import 'features/home/home_screen.dart';
import 'features/settings/flag_manager_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => FeatureFlagService()..loadFlags(),
      child: const FeatureFlagsApp(),
    ),
  );
}

class FeatureFlagsApp extends StatelessWidget {
  const FeatureFlagsApp({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.select<FeatureFlagService, bool>(
      (svc) => svc.isEnabled(FlagKeys.generalDarkMode),
    );

    return MaterialApp(
      title: 'Feature Flags Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF4f46e5),
        brightness: Brightness.light,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: const Color(0xFF4f46e5),
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      initialRoute: '/',
      routes: {
        '/': (_) => const HomeScreen(),
        '/flags': (_) => const FlagManagerScreen(),
      },
    );
  }
}
