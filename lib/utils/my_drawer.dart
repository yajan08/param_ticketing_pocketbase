import 'package:flutter/material.dart';
import 'package:param_ticketing/screens/analytics_page.dart';
import 'package:param_ticketing/screens/customer_page.dart';
import '../pb.dart';

class MyDrawer extends StatelessWidget {
  const MyDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    // --- HARDCODED EARTHY PALETTE ---
    const Color colorBackground = Color(0xFFF6EAD4); // Light Cream
    const Color colorPrimary = Color(0xFF6B705C);    // Muted Olive
    const Color colorSecondary = Color(0xFFA2A595);  // Sage Green
    const Color colorTextDark = Color(0xFF3F4238);   // Deep Slate Olive

    // Get current user email from PocketBase AuthStore
    final String? userEmail = pb.authStore.record?.getStringValue('email');

    void logout() {
      pb.authStore.clear();
      Navigator.of(context).pushReplacementNamed('/login');
    }

    return Drawer(
      backgroundColor: colorBackground,
      child: Column(
        children: [
          // Logo and User Info Section
          DrawerHeader(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: colorSecondary.withAlpha(30),
                ),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.confirmation_number_outlined,
                  color: colorPrimary,
                  size: 60,
                ),
                const SizedBox(height: 12),
                Text(
                  userEmail ?? "User Account",
                  style: const TextStyle(
                    color: colorTextDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Home List Tile
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 4),
            child: ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              title: const Text(
                "H O M E",
                style: TextStyle(
                  color: colorTextDark,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  fontSize: 13,
                ),
              ),
              leading: const Icon(Icons.home_rounded, color: colorPrimary),
              onTap: () => Navigator.pop(context),
            ),
          ),

          // CUSTOMERS List Tile (Placeholder for now)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 4),
            child: ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              title: const Text(
                "C U S T O M E R S",
                style: TextStyle(
                  color: colorTextDark,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  fontSize: 13,
                ),
              ),
              leading: const Icon(Icons.people_alt_rounded, color: colorPrimary),
              onTap: () {
                Navigator.pop(context);
                // We will add navigation to CustomerPage here later
                Navigator.push(context, MaterialPageRoute(builder: (context) => const CustomerPage()));
              },
            ),
          ),

        if(userEmail == "person1@gmail.com")
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 4),
            child: ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              title: const Text(
                "A N A L Y T I C S",
                style: TextStyle(
                  color: colorTextDark,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  fontSize: 13,
                ),
              ),
              leading: const Icon(Icons.people_alt_rounded, color: colorPrimary),
              onTap: () {
                Navigator.pop(context);
                // We will add navigation to CustomerPage here later
                Navigator.push(context, MaterialPageRoute(builder: (context) => const AnalyticsPage()));
              },
            ),
          ),

          const Spacer(),
          
          // Logout Tile
          Padding(
            padding: const EdgeInsets.only(left: 15.0, right: 15.0, bottom: 10.0),
            child: ListTile(
              tileColor: colorSecondary.withAlpha(10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              title: const Text(
                "L O G O U T",
                style: TextStyle(
                  color: colorTextDark,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  fontSize: 13,
                ),
              ),
              leading: const Icon(Icons.logout_rounded, color: colorPrimary),
              onTap: logout,
            ),
          ),

          // Developer Contact Info
          Padding(
            padding: const EdgeInsets.only(bottom: 20.0),
            child: Text(
              "developer: yajanmehta@gmail.com",
              style: TextStyle(
                color: colorTextDark.withAlpha(150),
                fontSize: 10,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}