class Machine {
  final String id;
  final int machineUid; // Your internal sequence (1, 2, 3...)
  final String name;
  final String type; // 'weight' or 'packing'
  final List<String> ownerIds; // List of customer record IDs
  final String note;

  Machine({
    required this.id,
    required this.machineUid,
    required this.name,
    required this.type,
    required this.ownerIds,
    required this.note,
  });

  factory Machine.fromRecord(dynamic record) {
    return Machine(
      id: record.id,
      machineUid: record.getIntValue('machine_uid'),
      name: record.getStringValue('name'),
      type: record.getStringValue('type'),
      // PocketBase returns relations as a List of Strings
      ownerIds: record.getListValue<String>('owner'),
      note: record.getStringValue('note'),
    );
  }
}