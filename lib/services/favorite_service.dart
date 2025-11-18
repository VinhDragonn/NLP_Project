import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FavoriteService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String? get userId => _auth.currentUser?.uid;

  // Thêm phim vào favorite
  Future<void> addFavorite(String movieId, Map<String, dynamic> movieData) async {
    if (userId == null) return;
    await _firestore
        .collection('favorites')
        .doc(userId)
        .collection('movies')
        .doc(movieId)
        .set(movieData);
  }

  // Xóa phim khỏi favorite
  Future<void> removeFavorite(String movieId) async {
    if (userId == null) return;
    await _firestore
        .collection('favorites')
        .doc(userId)
        .collection('movies')
        .doc(movieId)
        .delete();
  }

  // Lấy danh sách favorite (stream)
  Stream<QuerySnapshot<Map<String, dynamic>>> getFavorites() {
    if (userId == null) {
      // Trả về stream rỗng nếu chưa đăng nhập
      return const Stream.empty();
    }
    return _firestore
        .collection('favorites')
        .doc(userId)
        .collection('movies')
        .snapshots();
  }

  // Kiểm tra một phim đã được yêu thích chưa
  Future<bool> isFavorite(String movieId) async {
    if (userId == null) return false;
    final doc = await _firestore
        .collection('favorites')
        .doc(userId)
        .collection('movies')
        .doc(movieId)
        .get();
    return doc.exists;
  }
} 