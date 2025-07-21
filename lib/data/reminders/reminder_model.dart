class ReminderModel {
  final String id;
  final String encryptedData;
  final String nonce;
  final String mac;
  final String encryptedContent;
  final String contentNonce;
  final String contentMac;
  final DateTime created;
  final DateTime updated;
  final String title;
  final String repeat;

  ReminderModel({
    required this.id,
    required this.encryptedData,
    required this.nonce,
    required this.mac,
    required this.encryptedContent,
    required this.contentNonce,
    required this.contentMac,
    required this.created,
    required this.updated,
    required this.title,
    required this.repeat,
  });

  factory ReminderModel.fromMap(String id, Map<String, dynamic> map) {
    return ReminderModel(
      id: id,
      encryptedData: map['encryptedData'] as String,
      nonce: map['nonce'] as String,
      mac: map['mac'] as String? ?? '',
      encryptedContent: map['encryptedContent'] as String? ?? '',
      contentNonce: map['contentNonce'] as String? ?? '',
      contentMac: map['contentMac'] as String? ?? '',
      created: DateTime.parse(map['created'] as String),
      updated: DateTime.parse(map['updated'] as String),
      title: map['title'] as String,
      repeat: map['repeat'] as String? ?? 'None',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'encryptedData': encryptedData,
      'nonce': nonce,
      'mac': mac,
      'encryptedContent': encryptedContent,
      'contentNonce': contentNonce,
      'contentMac': contentMac,
      'created': created.toIso8601String(),
      'updated': updated.toIso8601String(),
      'title': title,
      'repeat': repeat,
    };
  }
}
