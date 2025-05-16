import 'package:cloud_firestore/cloud_firestore.dart';

class NoteRepository {
  final FirebaseFirestore _firestore;

  NoteRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<QuerySnapshot> getNotesStream() {
    return _firestore.collection('notes').orderBy('createdAt', descending: true).snapshots();
  }

  Future<String> addNote(String title, String content) async {
    final docRef = await _firestore.collection('notes').add({
      'title': title,
      'content': content,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  Future<void> updateNote(String id, String title, String content) async {
    await _firestore.collection('notes').doc(id).update({
      'title': title,
      'content': content,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteNote(String id) async {
    await _firestore.collection('notes').doc(id).delete();
  }
}