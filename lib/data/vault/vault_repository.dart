import 'package:cloud_firestore/cloud_firestore.dart';
import 'vault_model.dart';

class VaultRepository {
  final FirebaseFirestore firestore;
  final String userId;

  VaultRepository({required this.firestore, required this.userId});

  CollectionReference get _vaultRef =>
      firestore.collection('users').doc(userId).collection('vault');

  Stream<List<VaultModel>> getVaultItems() {
    return _vaultRef.orderBy('updated', descending: true).snapshots().map(
        (snapshot) => snapshot.docs
            .map((doc) =>
                VaultModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
            .toList());
  }

  Future<void> addVaultItem(VaultModel item) async {
    await _vaultRef.add(item.toMap());
  }

  Future<void> updateVaultItem(VaultModel item) async {
    await _vaultRef.doc(item.id).update(item.toMap());
  }

  Future<void> deleteVaultItem(String itemId) async {
    await _vaultRef.doc(itemId).delete();
  }
}
