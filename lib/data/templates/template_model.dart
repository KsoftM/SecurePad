class TemplateModel {
  final String id;
  final String encryptedData;
  final String nonce;
  final String mac;
  final DateTime created;
  final DateTime updated;
  final String name;

  TemplateModel({
    required this.id,
    required this.encryptedData,
    required this.nonce,
    required this.mac,
    required this.created,
    required this.updated,
    required this.name,
  });

  factory TemplateModel.fromMap(String id, Map<String, dynamic> map) {
    return TemplateModel(
      id: id,
      encryptedData: map['encryptedData'] as String,
      nonce: map['nonce'] as String,
      mac: map['mac'] as String? ?? '',
      created: DateTime.parse(map['created'] as String),
      updated: DateTime.parse(map['updated'] as String),
      name: map['name'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'encryptedData': encryptedData,
      'nonce': nonce,
      'mac': mac,
      'created': created.toIso8601String(),
      'updated': updated.toIso8601String(),
      'name': name,
    };
  }
}
