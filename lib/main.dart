import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/tontine_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TontineProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Gestion Tontine',
            debugShowCheckedModeBanner: false,
            theme: themeProvider.getTheme(),
            home: const LoginScreen(),
          );
        },
      ),
    );
  }
}