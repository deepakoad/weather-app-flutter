import 'package:flutter/material.dart';
import 'package:project_mohali/views/screens/splash_screen.dart';
import 'package:provider/provider.dart';
import 'viewmodels/theme_view_model.dart';
import 'viewmodels/weather_view_model.dart';
import 'views/screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AppRoot());
}

class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeViewModel()..load()),
        ChangeNotifierProvider(create: (_) => WeatherViewModel()),
      ],
      child: Consumer<ThemeViewModel>(
        builder: (context, themeVM, _) {
          return MaterialApp(
            title: 'Weather + Thought',
            debugShowCheckedModeBanner: false,
            theme: themeVM.lightTheme,
            darkTheme: themeVM.darkTheme,
            themeMode: themeVM.isDark ? ThemeMode.dark : ThemeMode.light,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
