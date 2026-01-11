import 'package:pocketbase/pocketbase.dart'; // Required for RecordSubscriptionEvent
import '../pb.dart';
import '../models/customer_model.dart';

class CustomerService {
  // Fetch all customers (Newest first)
  static Future<List<Customer>> getCustomers() async {
    final records = await pb.collection('customers').getFullList(sort: '-created');
    return records.map((record) => Customer.fromRecord(record)).toList();
  }

  // --- NEW: REAL-TIME LISTENER ---
  // Allows your UI to automatically refresh when a customer is added, edited, or deleted
  static Future<UnsubscribeFunc> subscribe(Function(RecordSubscriptionEvent) onEvent) async {
    return await pb.collection('customers').subscribe('*', onEvent);
  }

  // Add a new customer
  static Future<void> addCustomer(Map<String, dynamic> data) async {
    await pb.collection('customers').create(body: data);
  }

  // Update customer (phone, notes, etc.)
  static Future<void> updateCustomer(String id, Map<String, dynamic> data) async {
    await pb.collection('customers').update(id, body: data);
  }
}