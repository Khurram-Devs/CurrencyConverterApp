import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:currency_converter_app/screen/home_screen.dart';
import 'package:currency_converter_app/screen/currency_converter_screen.dart'
    as converter;
import 'package:currency_converter_app/screen/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  final int initialTabIndex;

  const MyApp({super.key, this.initialTabIndex = 0});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isDarkMode = false;
  bool isConversionHistory = true;
  bool isLoading = true;
  late int selectedIndex;

  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    selectedIndex = widget.initialTabIndex;
    _loadTheme();
    _loadConversionHistoryTurn();
    _loadSettings();
  }

  void _loadSettings() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final doc =
          await FirebaseFirestore.instance
              .collection('settings')
              .doc(uid)
              .get();
      final value = doc.data()?['conversion_history'];
      setState(() {
        isConversionHistory = value != 'off';
      });
    }
  }

  Future<void> _loadTheme() async {
    if (user != null) {
      final doc =
          await FirebaseFirestore.instance
              .collection('settings')
              .doc(user!.uid)
              .get();

      if (doc.exists && doc.data()!.containsKey('theme')) {
        setState(() {
          isDarkMode = doc.data()!['theme'] == 'dark';
          isLoading = false;
        });
      } else {
        // Default if no saved theme
        final brightness =
            WidgetsBinding.instance.platformDispatcher.platformBrightness;
        isDarkMode = brightness == Brightness.dark;
        await _saveThemeToFirestore();
        setState(() => isLoading = false);
      }
    } else {
      // Guest user – use light theme
      setState(() {
        isDarkMode = false;
        isLoading = false;
      });
    }
  }

  Future<void> _loadConversionHistoryTurn() async {
    if (user != null) {
      final doc =
          await FirebaseFirestore.instance
              .collection('settings')
              .doc(user!.uid)
              .get();

      if (doc.exists && doc.data()!.containsKey('conversion_history')) {
        setState(() {
          isConversionHistory = doc.data()!['conversion_history'] == 'on';
          isLoading = false;
        });
      } else {
        // Default if no saved setting
        isConversionHistory = true;
        await _saveThemeToFirestore();
        setState(() => isLoading = false);
      }
    } else {
      // Guest user – history turn on
      setState(() {
        isConversionHistory = true;
        isLoading = false;
      });
    }
  }

  Future<void> _saveThemeToFirestore() async {
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('settings')
          .doc(user!.uid)
          .set({
            'theme': isDarkMode ? 'dark' : 'light',
          }, SetOptions(merge: true));
    }
  }

  void toggleTheme() {
    setState(() => isDarkMode = !isDarkMode);
    _saveThemeToFirestore();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      HomeScreen(),
      converter.CurrencyConverterScreen(isConversionHistory: false),
      converter.CurrencyConverterScreen(isConversionHistory: true),
      SettingsScreen(
        onConversionHistoryChanged: (value) {
          setState(() => isConversionHistory = value);
        },
      ),
    ];

    if (isLoading) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return MaterialApp(
      title: 'Currency Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        textTheme: GoogleFonts.robotoTextTheme(ThemeData.light().textTheme),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        textTheme: GoogleFonts.robotoTextTheme(ThemeData.dark().textTheme),
      ),
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      routes: {
        '/home': (_) => const MyApp(initialTabIndex: 0),
        '/convert': (_) => const MyApp(initialTabIndex: 1),
        '/history': (_) => const MyApp(initialTabIndex: 2),
        '/settings': (_) => const MyApp(initialTabIndex: 3),
      },
      home: Scaffold(
        appBar: AppBar(
          title: LayoutBuilder(
            builder: (context, constraints) {
              double width = constraints.maxWidth;
              double fontSize;
              if (width >= 1024) {
                fontSize = 40;
              } else if (width >= 600) {
                fontSize = 26;
              } else {
                fontSize = 20;
              }

              return Text(
                'CURRENCY TRACKER',
                style: TextStyle(
                  fontSize: fontSize,
                  letterSpacing: 3,
                  wordSpacing: 4,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(isDarkMode ? Icons.dark_mode : Icons.light_mode),
              onPressed: toggleTheme,
              tooltip:
                  isDarkMode ? "Switch to Light Mode" : "Switch to Dark Mode",
            ),
            if (user != null)
              IconButton(
                icon: const Icon(Icons.logout),
                tooltip: 'Logout',
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  Navigator.of(context, rootNavigator: true).pushNamed('/home');
                },
              ),
          ],
        ),
        body: screens[selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: selectedIndex,
          selectedItemColor: Colors.blueAccent,
          unselectedItemColor: Colors.grey,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(
              icon: Icon(Icons.currency_exchange_rounded),
              label: 'Convert',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bookmark_border),
              label: 'My Tracks',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
          onTap: (index) {
            setState(() => selectedIndex = index);
          },
        ),
      ),
    );
  }
}
