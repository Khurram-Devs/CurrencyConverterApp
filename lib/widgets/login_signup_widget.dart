import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:currency_converter_app/main.dart';

class LoginSignupWidget extends StatefulWidget {
  const LoginSignupWidget({super.key});

  @override
  State<LoginSignupWidget> createState() => _LoginSignupWidgetState();
}

class _LoginSignupWidgetState extends State<LoginSignupWidget> {
  final _formKey = GlobalKey<FormState>();
  bool isLogin = true;
  String email = '';
  String password = '';
  final auth = FirebaseAuth.instance;

  void submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      try {
        if (isLogin) {
          await auth.signInWithEmailAndPassword(email: email, password: password);
          _showMessage('Login successful!');
        } else {
          await auth.createUserWithEmailAndPassword(email: email, password: password);
          _showMessage('Account created and logged in!');
        }

        Navigator.of(
                    context,
                    rootNavigator: true,
                  ).pushNamed('/home');

      } on FirebaseAuthException catch (e) {
        if (isLogin && e.code == 'user-not-found') {
          setState(() => isLogin = false);
          _showMessage('Account does not exist. Please create one.');
        } else if (e.code == 'wrong-password') {
          _showMessage('Incorrect password.');
        } else if (e.code == 'invalid-email') {
          _showMessage('Invalid email format.');
        } else {
          _showMessage(e.message ?? 'Authentication error occurred.');
        }
      }

      setState(() {});
    }
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void toggleForm() => setState(() => isLogin = !isLogin);

  void forgotPassword() {
    if (email.isNotEmpty) {
      auth.sendPasswordResetEmail(email: email);
      _showMessage('Password reset email sent.');
    } else {
      _showMessage('Please enter your email first.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final availableHeight = mediaQuery.size.height - kToolbarHeight - mediaQuery.padding.top;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      child: Container(
        height: availableHeight,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(127),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isLogin ? 'Welcome Back 👋' : 'Create Account 📝',
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    onSaved: (value) => email = value!.trim(),
                    validator: (value) => value == null || !value.contains('@') ? 'Enter a valid email' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    obscureText: true,
                    onSaved: (value) => password = value!,
                    validator: (value) => value == null || value.length < 6 ? 'Minimum 6 characters required' : null,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: submit,
                      style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                      child: Text(
                        isLogin ? 'Login' : 'Sign Up',
                        style: const TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: forgotPassword,
                    child: Text(
                      "Forgot Password?",
                      style: TextStyle(
                        color: Colors.blueAccent,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isLogin ? "Don't have an account?" : "Already have an account?",
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: toggleForm,
                        child: Text(
                          isLogin ? "Sign up" : "Log in",
                          style: const TextStyle(
                            color: Colors.blueAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
