import 'package:cloud_firestore/cloud_firestore.dart';
import 'note_model.dart';

class NotesRepository {
  final FirebaseFirestore firestore;
  final String userId;

  NotesRepository({required this.firestore, required this.userId});

  CollectionReference get _notesRef =>
      firestore.collection('users').doc(userId).collection('notes');

  Stream<List<NoteModel>> getNotes() {
    return _notesRef.orderBy('updated', descending: true).snapshots().map(
        (snapshot) => snapshot.docs
            .map((doc) =>
                NoteModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
            .toList());
  }

  Future<void> addNote(NoteModel note) async {
    await _notesRef.add(note.toMap());
  }

  Future<void> updateNote(NoteModel note) async {
    await _notesRef.doc(note.id).update(note.toMap());
  }

  Future<void> deleteNote(String noteId) async {
    await _notesRef.doc(noteId).delete();
  }
}
