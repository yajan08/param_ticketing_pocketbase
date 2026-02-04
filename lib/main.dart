import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:param_ticketing/screens/customer_selection_screen.dart';
import 'package:param_ticketing/screens/add_ticket_screen.dart';
import 'pb.dart';
import 'auth/auth_gate.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() async {

  WidgetsFlutterBinding.ensureInitialized();

  // to hide the navigation buttons on older style navigation on phones.
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.immersiveSticky,
  );

  // Initialize persistence before running the app
  await initPocketBase();

  runApp(const TicketingApp());
}

class TicketingApp extends StatelessWidget {
  const TicketingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ticketing Tool',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6B705C)),
        useMaterial3: true,
      ),
      home: const AuthGate(),
      
      routes: {
      '/login': (context) => const LoginScreen(),
      '/home': (context) => const HomeScreen(),
      '/add-ticket': (context) => const AddTicketScreen(),
      '/add-customer': (context) => const CustomerSelectionScreen(), // Add this!
      },
    );
  }
}