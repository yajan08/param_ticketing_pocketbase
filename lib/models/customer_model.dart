class Customer {
  final String id;
  final String name;
  final String primaryPhone;
  final String secondaryPhone;
  final String company;
  final String note;

  Customer({
    required this.id,
    required this.name,
    required this.primaryPhone,
    required this.secondaryPhone,
    required this.company,
    required this.note,
  });

  // Map PocketBase RecordModel to our Dart Class
  factory Customer.fromRecord(dynamic record) {
    return Customer(
      id: record.id,
      name: record.getStringValue('name'),
      primaryPhone: record.getStringValue('primary_phone'),
      secondaryPhone: record.getStringValue('secondary_phone'),
      company: record.getStringValue('company'),
      note: record.getStringValue('note'),
    );
  }
}