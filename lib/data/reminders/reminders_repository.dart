import 'package:cloud_firestore/cloud_firestore.dart';
import 'reminder_model.dart';

class RemindersRepository {
  final FirebaseFirestore firestore;
  final String userId;

  RemindersRepository({required this.firestore, required this.userId});

  CollectionReference get _remindersRef =>
      firestore.collection('users').doc(userId).collection('reminders');

  Stream<List<ReminderModel>> getReminders() {
    return _remindersRef.orderBy('updated', descending: true).snapshots().map(
        (snapshot) => snapshot.docs
            .map((doc) => ReminderModel.fromMap(
                doc.id, doc.data() as Map<String, dynamic>))
            .toList());
  }

  Future<void> addReminder(ReminderModel reminder) async {
    await _remindersRef.add(reminder.toMap());
  }

  Future<void> updateReminder(ReminderModel reminder) async {
    await _remindersRef.doc(reminder.id).update(reminder.toMap());
  }

  Future<void> deleteReminder(String reminderId) async {
    await _remindersRef.doc(reminderId).delete();
  }
}
