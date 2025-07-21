class NoteEntity {
  final String id;
  final String encryptedData;
  final String nonce;
  final DateTime created;
  final DateTime updated;
  final List<String> tags;

  NoteEntity({
    required this.id,
    required this.encryptedData,
    required this.nonce,
    required this.created,
    required this.updated,
    required this.tags,
  });
}
