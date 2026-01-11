import 'package:pocketbase/pocketbase.dart'; // Required for UnsubscribeFunc
import '../models/machine_model.dart';
import '../pb.dart';
import 'counter_service.dart';

class MachineService {
  // 1. Fetch all machines
  static Future<List<Machine>> getMachines() async {
    final records = await pb.collection('machines').getFullList(
      sort: '-created',
    );
    return records.map((record) => Machine.fromRecord(record)).toList();
  }

  // 2. NEW: Real-time listener
  // Returns a function that you must call when the widget is disposed to stop listening.
  static Future<UnsubscribeFunc> subscribe(Function(RecordSubscriptionEvent) onEvent) async {
    return await pb.collection('machines').subscribe('*', onEvent);
  }

  // 3. Create a machine with logic check
  static Future<void> createMachine({
    required String name,
    required String type,
    required List<String> customerIds,
    required String note,
  }) async {
    try {
      final int nextUid = await CounterService.getNextId('machines');

      await pb.collection('machines').create(body: {
        'machine_uid': nextUid,
        'name': name,
        'type': type,
        'owner': customerIds, 
        'note': note,
      });
    } catch (e) {
      // Logic failure (e.g., counter record not found in PB)
      throw Exception("Failed to create machine: $e");
    }
  }

  // 4. Update existing machine
  static Future<void> updateMachine(String id, Map<String, dynamic> data) async {
    try {
      await pb.collection('machines').update(id, body: data);
    } catch (e) {
      throw Exception("Failed to update machine: $e");
    }
  }
}