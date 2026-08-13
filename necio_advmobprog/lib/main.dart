// packages
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Starts the app and provides [ThemeModel] to the widget tree using Provider.
void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeModel(),
      child: const MyApp(),
    ), // ChangeNotifierProvider
  );
}

/// Root widget that builds [MaterialApp] and applies the current light/dark theme.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  /// Reads [ThemeModel] and returns the themed app with [CounterPage] as home.
  @override
  Widget build(BuildContext context) {
    final themeModel = Provider.of<ThemeModel>(context);

    return MaterialApp(
      theme: themeModel.isDark ? ThemeData.dark() : ThemeData.light(),
      home: const CounterPage(),
    ); // MaterialApp
  }
}

/// Holds app-wide theme state and notifies listeners when the theme changes.
class ThemeModel with ChangeNotifier {
  bool _isDark = false;

  /// Returns whether dark theme is currently enabled.
  bool get isDark => _isDark;

  /// Switches between light and dark theme and notifies listening widgets.
  void toggleTheme() {
    _isDark = !_isDark;
    notifyListeners();
  }
}

/// First screen that shows a counter using ephemeral (local) state.
class CounterPage extends StatefulWidget {
  const CounterPage({super.key});

  /// Creates the mutable state object for this page.
  @override
  State<CounterPage> createState() => _CounterPageState();
}

/// Manages the counter value and UI updates for [CounterPage].
class _CounterPageState extends State<CounterPage> {
  int _counter = 0;

  /// Increases the counter by one and rebuilds the screen with setState.
  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  /// Builds the counter UI and a button to open the theme screen.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ephemeral State Example'),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ThemePage(),
                ),
              );
            },
          ), // IconButton
        ],
      ), // AppBar
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ), // Text
          ], // <Widget>[]
        ), // Column
      ), // Center
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // FloatingActionButton
    ); // Scaffold
  }
}

/// Second screen that toggles the app theme using Provider app state.
class ThemePage extends StatelessWidget {
  const ThemePage({super.key});

  /// Builds the theme switch UI and updates [ThemeModel] when toggled.
  @override
  Widget build(BuildContext context) {
    final themeModel = Provider.of<ThemeModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('App State Example'),
      ), // AppBar
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Toggle the theme using the switch below.'),
            Switch(
              value: themeModel.isDark,
              onChanged: (_) => themeModel.toggleTheme(),
            ), // Switch
          ],
        ), // Column
      ), // Center
    ); // Scaffold
  }
}
