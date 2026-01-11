import 'package:flutter/material.dart';
import '../pb.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  // Create a dedicated check function to avoid logic inside build
  Future<bool> _isUserBanned() async {
  if (!pb.authStore.isValid || pb.authStore.record == null) return false;
  
  final userEmail = pb.authStore.record!.getStringValue('email');
  try {
    // Add a 5-second timeout to prevent infinite loading
    final result = await pb.collection('banned_users').getList(
      filter: 'email = "$userEmail"',
    ).timeout(const Duration(seconds: 5));
    
    if (result.items.isNotEmpty) {
      pb.authStore.clear();
      return true;
    }
    return false;
  } catch (e) {
    debugPrint("AuthGate Error: $e");
    // If it times out or fails, let them in to the Home Screen 
    // rather than locking them out on a loading screen.
    return false; 
  }
}

  @override
  Widget build(BuildContext context) {
    // 1. Instant local check
    if (!pb.authStore.isValid || pb.authStore.record == null) {
      return const LoginScreen();
    }

    // 2. Verified check (Banned Check)
    return FutureBuilder<bool>(
      future: _isUserBanned(),
      builder: (context, snapshot) {
        // Show a clean loading screen while checking database
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF6B705C)),
            ),
          );
        }

        // If banned (true), show Login. Otherwise, show Home.
        if (snapshot.data == true) {
          return const LoginScreen();
        }

        return const HomeScreen();
      },
    );
  }
}

// import 'package:flutter/material.dart';
// import '../pb.dart';
// import '../screens/home_screen.dart';
// import '../screens/login_screen.dart';

// class AuthGate extends StatelessWidget {
//   const AuthGate({super.key});

//   @override
//   Widget build(BuildContext context) {
//     // 1. Check if the local session token is valid
//     // This is an instant check against the local storage
//     if (pb.authStore.isValid && pb.authStore.record != null) {
//       return const HomeScreen();
//     }

//     // 2. If no valid session, redirect to Login
//     return const LoginScreen();
//   }
// }