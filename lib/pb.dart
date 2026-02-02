import 'package:pocketbase/pocketbase.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Create a global instance, but we will initialize its store in main()
late final PocketBase pb;

Future<void> initPocketBase() async {

  final prefs = await SharedPreferences.getInstance();
  
  // Use AsyncAuthStore to save the token to local storage
  final store = AsyncAuthStore(
    save: (String data) async => prefs.setString('pb_auth', data),
    initial: prefs.getString('pb_auth'),
  );
 
  pb = PocketBase(
    'https://pbserver.paramgroup.net',
    authStore: store,
  );
  
}
