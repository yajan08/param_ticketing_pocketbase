import 'package:flutter/material.dart';
import '../pb.dart'; // Your PocketBase instance
import '../utils/my_button.dart';
import '../utils/my_textfield.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  // --- HARDCODED COLOR PALETTE ---
  final Color colorBackground = const Color(0xFFF6EAD4); // Light Cream
  final Color colorPrimary = const Color(0xFF6B705C);    // Muted Olive
  final Color colorSecondary = const Color(0xFFA2A595);  // Sage Green
  final Color colorTextDark = const Color(0xFF3F4238);   // Dark Olive

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showError("Please fill in all fields");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // --- ADDED: PRE-AUTH BAN CHECK ---
      final bannedList = await pb.collection('banned_users').getList(
        filter: 'email = "$email"',
      ).timeout(const Duration(seconds: 5)); // 5 second timeout;

      if (bannedList.items.isNotEmpty) {
        final reason = bannedList.items.first.getStringValue('reason');
        _showError("Access Denied: $reason");
        setState(() => _isLoading = false);
        return;
      }
      // ---------------------------------

      // 1. Authenticate with PocketBase
      await pb.collection('users').authWithPassword(email, password).timeout(const Duration(seconds: 10));

      // 2. Navigate to Home if successful
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/home');
      
    } catch (e) {
    _showError("Login Error: $e");
  } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 25.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colorSecondary.withAlpha(20),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.confirmation_number_rounded,
                    size: 80,
                    color: colorPrimary,
                  ),
                ),
                const SizedBox(height: 40),

                // Title
                Text(
                  "Param's Ticket Tool",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colorTextDark,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 10),

                // Subtitle
                Text(
                  "Manage your tasks efficiently",
                  style: TextStyle(
                    color: colorPrimary,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 50),

                // Textfields
                MyTextField(
                  hintText: "Email",
                  obscureText: false,
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 15),
                MyTextField(
                  hintText: "Password",
                  obscureText: true,
                  controller: _passwordController,
                ),
                const SizedBox(height: 35),

                // Loading or Button
                _isLoading
                    ? CircularProgressIndicator(color: colorPrimary)
                    : MyButton(
                        buttonText: "Sign In",
                        onTap: _handleLogin,
                      ),
                const SizedBox(height: 30),
                // --- NEW FOOTER SECTION ---
                
                // 1. Divider with text in middle
                Row(
                  children: [
                    Expanded(child: Divider(color: colorSecondary.withAlpha(100))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        "Need a demo or an account?",
                        style: TextStyle(color: colorPrimary, fontSize: 14),
                      ),
                    ),
                    Expanded(child: Divider(color: colorSecondary.withAlpha(100))),
                  ],
                ),
                const SizedBox(height: 20),

                // 2. Email in capsule shape
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(50), // Large radius for capsule shape
                  ),
                  child: Text(
                    "yajanmehta@gmail.com",
                    style: TextStyle(
                      color: colorPrimary,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}