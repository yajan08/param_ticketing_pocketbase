import 'package:flutter/material.dart';
import '../pb.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Check if the local session token is valid
    if (pb.authStore.isValid && pb.authStore.record != null) {
      final userEmail = pb.authStore.record!.getStringValue('email');

      return FutureBuilder(
        // Check if this specific email is in the banned collection
        future: pb.collection('banned_users').getList(
          filter: 'email = "$userEmail"',
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }

          // If the list is not empty, the user has been banned since their last login
          if (snapshot.hasData && snapshot.data!.items.isNotEmpty) {
            pb.authStore.clear(); // Log them out locally
            return const LoginScreen();
          }

          return const HomeScreen();
        },
      );
    }

    // 2. If no valid session, redirect to Login
    return const LoginScreen();
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