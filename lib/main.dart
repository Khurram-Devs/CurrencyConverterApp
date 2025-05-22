import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'screen/home_screen.dart';
import 'screen/currency_converter_screen.dart';
import 'screen/settings_screen.dart';
import 'package:google_fonts/google_fonts.dart';

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
  bool isDarkMode = true;
  late int selectedIndex;

  @override
  void initState() {
    super.initState();
    selectedIndex = widget.initialTabIndex;
  }

  void toggleTheme() {
    setState(() {
      isDarkMode = !isDarkMode;
    });
  }

  final List<Widget> screens = [
    HomeScreen(),
    CurrencyConverterScreen(),
    CurrencyConverterScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Currency Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        textTheme: GoogleFonts.robotoTextTheme(
          ThemeData.light().textTheme,
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        textTheme: GoogleFonts.robotoTextTheme(
          ThemeData.dark().textTheme,
        ),
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
              tooltip: isDarkMode ? "Switch to Light Mode" : "Switch to Dark Mode",
            ),
            if (FirebaseAuth.instance.currentUser != null)
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
            setState(() {
              selectedIndex = index;
            });
          },
        ),
      ),
    );
  }
}
