import 'package:cloud_firestore/cloud_firestore.dart';
import 'template_model.dart';

class TemplatesRepository {
  final FirebaseFirestore firestore;
  final String userId;

  TemplatesRepository({required this.firestore, required this.userId});

  CollectionReference get _templatesRef =>
      firestore.collection('users').doc(userId).collection('templates');

  Stream<List<TemplateModel>> getTemplates() {
    return _templatesRef.orderBy('updated', descending: true).snapshots().map(
        (snapshot) => snapshot.docs
            .map((doc) => TemplateModel.fromMap(
                doc.id, doc.data() as Map<String, dynamic>))
            .toList());
  }

  Future<void> addTemplate(TemplateModel template) async {
    await _templatesRef.add(template.toMap());
  }

  Future<void> updateTemplate(TemplateModel template) async {
    await _templatesRef.doc(template.id).update(template.toMap());
  }

  Future<void> deleteTemplate(String templateId) async {
    await _templatesRef.doc(templateId).delete();
  }
}
