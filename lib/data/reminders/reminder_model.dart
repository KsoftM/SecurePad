class ReminderModel {
  final String id;
  final String encryptedData;
  final String nonce;
  final DateTime created;
  final DateTime updated;
  final String title;

  ReminderModel({
    required this.id,
    required this.encryptedData,
    required this.nonce,
    required this.created,
    required this.updated,
    required this.title,
  });

  factory ReminderModel.fromMap(String id, Map<String, dynamic> map) {
    return ReminderModel(
      id: id,
      encryptedData: map['encryptedData'] as String,
      nonce: map['nonce'] as String,
      created: DateTime.parse(map['created'] as String),
      updated: DateTime.parse(map['updated'] as String),
      title: map['title'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'encryptedData': encryptedData,
      'nonce': nonce,
      'created': created.toIso8601String(),
      'updated': updated.toIso8601String(),
      'title': title,
    };
  }
}
