import '../pb.dart';

class CounterService {
  static Future<int> getNextId(String collectionName) async {
    // 1. Find the counter record for the specific collection
    final record = await pb.collection('counters').getFirstListItem(
      'collection_name = "$collectionName"',
    );

    // 2. Increment the last_id
    final int nextId = record.getIntValue('last_id') + 1;

    // 3. Update the counter record in PocketBase
    await pb.collection('counters').update(record.id, body: {
      'last_id': nextId,
    });

    return nextId;
  }
}