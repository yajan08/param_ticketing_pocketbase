import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pocketbase/pocketbase.dart'; // Ensure UnsubscribeFunc is available
import '../models/ticket_model.dart';
import '../pb.dart';
import 'counter_service.dart';

class TicketService {
  /// Fetches the initial full list of tickets with all expansions
  static Future<List<Ticket>> getTickets() async {
    final records = await pb.collection('tickets').getFullList(
      sort: '-created',
      expand: 'customer,machine,opened_by,done_by,closed_by',
    );
    return records.map((record) => Ticket.fromRecord(record)).toList();
  }

  /// REAL-TIME LISTENER
  static Future<UnsubscribeFunc> subscribeToTickets(
    Function(Ticket ticket, String action) onEvent) async {
    
  return await pb.collection('tickets').subscribe('*', (e) {
    if (e.record == null) return;

    // Convert the raw record from the server into our Ticket model
    final ticket = Ticket.fromRecord(e.record!);
    
    // Pass the specific ticket and the action (create/update/delete) to the UI
    onEvent(ticket, e.action);
  }, expand: 'customer,machine,opened_by,done_by,closed_by'); // CRITICAL: Expand must be here too!
}

  static Future<void> createTicket({
    required String customerId,
    required String machineId,
    required String problem,
    required bool warranty,
    required bool isOut,
    String note = "",
    List<File>? images, 
  }) async {
    final int nextUid = await CounterService.getNextId('tickets');
    List<http.MultipartFile> files = [];
    if (images != null) {
      for (var image in images) {
        files.add(await http.MultipartFile.fromPath('photos', image.path));
      }
    }

    await pb.collection('tickets').create(
      body: {
        'ticket_uid': nextUid,
        'status': 'open',
        'customer': customerId,
        'machine': machineId,
        'problem': problem,
        'warranty': warranty,
        'opened_by': pb.authStore.record?.id,
        'cost': 0,
        'work_done': '',
        'note': note,
        'is_out': isOut,
      },
      files: files, 
    );
  }

  static Future<void> updateTicket(String id, Map<String, dynamic> body, {List<http.MultipartFile>? files}) async {
    try {
      await pb.collection('tickets').update(
        id,
        body: body,
        files: files ?? [],
      );
    } catch (e) {
      debugPrint("PB Update Error: $e");
      throw Exception("Update Failed: $e");
    }
  }

  static String getImageUrl(String collectionId, String recordId, String fileName) {
    return '${pb.baseURL}/api/files/$collectionId/$recordId/$fileName';
  }
}