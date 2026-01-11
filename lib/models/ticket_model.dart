import 'package:pocketbase/pocketbase.dart';

class Ticket {
  final String id;
  final int ticketUid;
  final String status;
  final String customerId;
  final String machineId;
  final bool warranty;
  final String problem;
  final String workDone;
  final String note; // <--- Added this
  final double cost;
  final List<String> photos;
  final String openedBy;
  final String? doneBy;
  final String? closedBy;
  final DateTime? doneAt;
  final DateTime? closedAt;
  final DateTime created;

  Ticket({
    required this.id,
    required this.ticketUid,
    required this.status,
    required this.customerId,
    required this.machineId,
    required this.warranty,
    required this.problem,
    required this.workDone,
    required this.note, // <--- Added this
    required this.cost,
    required this.photos,
    required this.openedBy,
    required this.created,
    this.doneBy,
    this.closedBy,
    this.doneAt,
    this.closedAt,
  });

  factory Ticket.fromRecord(RecordModel record) {
    String getEmail(String field) {
      return record.get<String>("expand.$field.email", "Unknown");
    }

    return Ticket(
      id: record.id,
      created: DateTime.parse(record.get<String>('created', DateTime.now().toIso8601String())), 
      ticketUid: record.get<int>('ticket_uid', 0),
      status: record.get<String>('status', 'open'),
      customerId: record.get<String>('customer', ''),
      machineId: record.get<String>('machine', ''),
      warranty: record.get<bool>('warranty', false),
      problem: record.get<String>('problem', ''),
      workDone: record.get<String>('work_done', ''),
      note: record.get<String>('note', ''), // <--- Added this
      cost: record.get<num>('cost', 0).toDouble(),
      photos: record.get<List<String>>('photos', []),
      openedBy: getEmail('opened_by'),
      doneBy: record.get<String>('done_by', "").isNotEmpty ? getEmail('done_by') : null,
      closedBy: record.get<String>('closed_by', "").isNotEmpty ? getEmail('closed_by') : null,
      doneAt: record.get<String>('done_at', "").isNotEmpty ? DateTime.parse(record.get<String>('done_at')) : null,
      closedAt: record.get<String>('closed_at', "").isNotEmpty ? DateTime.parse(record.get<String>('closed_at')) : null,
    );
  }
}