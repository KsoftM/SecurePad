import 'package:cloud_firestore/cloud_firestore.dart';

class NoteModel {
  final String id;
  final String encryptedData;
  final String nonce;
  final String mac;
  final Timestamp created;
  final Timestamp updated;
  final List<String> tags;

  NoteModel({
    required this.id,
    required this.encryptedData,
    required this.nonce,
    required this.mac,
    required this.created,
    required this.updated,
    required this.tags,
  });

  factory NoteModel.fromMap(String id, Map<String, dynamic> map) {
    return NoteModel(
      id: id,
      encryptedData: map['encryptedData'] as String,
      nonce: map['nonce'] as String,
      mac: map['mac'] as String? ?? '',
      created: map['created'] as Timestamp,
      updated: map['updated'] as Timestamp,
      tags: List<String>.from(map['tags'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'encryptedData': encryptedData,
      'nonce': nonce,
      'mac': mac,
      'created': created,
      'updated': updated,
      'tags': tags,
    };
  }
}
