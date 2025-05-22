import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../widgets/login_signup_widget.dart';

class SettingsScreen extends StatefulWidget {
  final void Function(bool)? onConversionHistoryChanged;

  const SettingsScreen({super.key, this.onConversionHistoryChanged});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool isDarkMode = true;
  bool isConversionHistory = true;
  bool isLoading = true;
  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadThemeFromFirestore();
  }

  Future<void> _loadThemeFromFirestore() async {
    if (user == null) return;

    final doc =
        await FirebaseFirestore.instance
            .collection('settings')
            .doc(user!.uid)
            .get();

    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        isDarkMode = data['theme'] == 'dark';
        isConversionHistory =
            data['conversion_history'] != 'off'; // Default to ON if missing
        isLoading = false;
      });
    } else {
      // Use system theme if no doc found
      final brightness =
          WidgetsBinding.instance.platformDispatcher.platformBrightness;
      isDarkMode = brightness == Brightness.dark;
      isConversionHistory = true; // Default to ON
      _saveThemeToFirestore();
      _saveConversionHistoryTurnToFirestore();
      setState(() => isLoading = false);
    }
  }

  Future<void> _saveThemeToFirestore() async {
    if (user == null) return;

    await FirebaseFirestore.instance.collection('settings').doc(user!.uid).set({
      'theme': isDarkMode ? 'dark' : 'light',
    }, SetOptions(merge: true));
  }

  Future<void> _saveConversionHistoryTurnToFirestore() async {
    if (user == null) return;

    await FirebaseFirestore.instance.collection('settings').doc(user!.uid).set({
      'conversion_history': isConversionHistory ? 'on' : 'off',
    }, SetOptions(merge: true));
  }

  void _toggleTheme() {
    setState(() => isDarkMode = !isDarkMode);
    _saveThemeToFirestore();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Theme changed to ${isDarkMode ? 'Dark' : 'Light'} mode'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _toggleConversionHistory() {
  setState(() => isConversionHistory = !isConversionHistory);
  _saveConversionHistoryTurnToFirestore();

  if (widget.onConversionHistoryChanged != null) {
    widget.onConversionHistoryChanged!(isConversionHistory);
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Conversion History Turned ${isConversionHistory ? 'On' : 'Off'}'),
      duration: const Duration(seconds: 2),
    ),
  );
}


  Future<void> _clearHistory() async {
    final uid = user?.uid;
    if (uid == null) return;

    try {
      setState(() => isLoading = true);

      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('conversions_history')
              .where('userId', isEqualTo: uid)
              .get();

      for (var doc in querySnapshot.docs) {
        await doc.reference.delete();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Conversion history cleared')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to clear history: $e')));
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) return const LoginSignupWidget();
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text("Logged in as"),
            subtitle: Text(user!.email ?? "No email"),
          ),
          const Divider(),
          SwitchListTile(
            secondary: const Icon(Icons.brightness_6),
            title: const Text("Dark Mode"),
            value: isDarkMode,
            onChanged: (_) => _toggleTheme(),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.history),
            title: const Text("Save Conversion History"),
            value: isConversionHistory,
            onChanged: (_) => _toggleConversionHistory(),
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever),
            title: const Text("Clear Conversion History"),
            onTap: _clearHistory,
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text("Logout"),
            onTap: _logout,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text("App Version"),
            subtitle: const Text("1.0.0 BETA"),
          )
        ],
      ),
    );
  }
}
