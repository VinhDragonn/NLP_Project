import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HistoryService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String? get userId => _auth.currentUser?.uid;

  // Thêm phim vào history
  Future<void> addHistory(String movieId, Map<String, dynamic> movieData) async {
    if (userId == null) return;
    await _firestore
        .collection('history')
        .doc(userId)
        .collection('movies')
        .doc(movieId)
        .set(movieData);
  }

  // Xóa phim khỏi history
  Future<void> removeHistory(String movieId) async {
    if (userId == null) return;
    await _firestore
        .collection('history')
        .doc(userId)
        .collection('movies')
        .doc(movieId)
        .delete();
  }

  // Lấy danh sách history (stream)
  Stream<QuerySnapshot<Map<String, dynamic>>> getHistory() {
    if (userId == null) {
      // Trả về stream rỗng nếu chưa đăng nhập
      return const Stream.empty();
    }
    return _firestore
        .collection('history')
        .doc(userId)
        .collection('movies')
        .orderBy('watched_at', descending: true)
        .snapshots();
  }
} 