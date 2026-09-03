// packages
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

// screens
import 'screens/cart_screen.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/signin_screen.dart';
import 'screens/splash_screen.dart';

// providers
import 'providers/theme_provider.dart';

// services
import 'services/cart_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]).then(
  (
    _,
  ) async {
    await dotenv.load(fileName: 'assets/.env');
    runApp(const RoblesAdvMobProg());
  });
}

class RoblesAdvMobProg extends StatelessWidget {
  const RoblesAdvMobProg({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => CartService()..loadUserCart()),
      ],
      child: ScreenUtilInit(
        designSize: const Size(412, 715),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (build, child) {
          final themeModel = build.watch<ThemeProvider>();
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: themeModel.lightTheme,
            darkTheme: themeModel.darkTheme,
            themeMode: themeModel.isDark ? ThemeMode.dark : ThemeMode.light,
            title: 'E-Commerce App',
            initialRoute: '/splash',
            routes: {
              '/splash': (context) => const SplashScreen(),
              '/signin': (context) => const SignInScreen(),
              '/home': (context) => const HomeScreen(),
              // ENHANCEMENT 1: Route to cart_screen to render the carts API endpoint.
              '/cart': (context) => const CartScreen(),
              // ENHANCEMENT 3: Route to settings page for dark/light mode switch.
              '/settings': (context) => const SettingsScreen(),
            },
          );
        },
      ),
    );
  }
}
