import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:fluttertoast/fluttertoast.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Lấy user hiện tại
  User? get currentUser => _auth.currentUser;

  // Stream để lắng nghe thay đổi trạng thái đăng nhập
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Đăng nhập với email và password
  Future<UserCredential?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential userCredential =
          await _auth.signInWithEmailAndPassword(email: email, password: password);
      Fluttertoast.showToast(
        msg: "Đăng nhập thành công!",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      String message = "Đăng nhập thất bại";
      if (e.code == 'user-not-found') {
        message = "Không tìm thấy tài khoản với email này";
      } else if (e.code == 'wrong-password') {
        message = "Mật khẩu không đúng";
      } else if (e.code == 'invalid-email') {
        message = "Email không hợp lệ";
      } else if (e.code == 'user-disabled') {
        message = "Tài khoản đã bị vô hiệu hóa";
      }
      Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
      );
      return null;
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Có lỗi xảy ra: $e",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
      );
      return null;
    }
  }

  // Đăng nhập với Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // User cancelled the sign-in
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      UserCredential userCredential = await _auth.signInWithCredential(credential);
      
      Fluttertoast.showToast(
        msg: "Đăng nhập Google thành công!",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
      
      return userCredential;
    } on FirebaseAuthException catch (e) {
      String message = "Đăng nhập Google thất bại";
      if (e.code == 'account-exists-with-different-credential') {
        message = "Tài khoản đã tồn tại với phương thức đăng nhập khác";
      } else if (e.code == 'invalid-credential') {
        message = "Thông tin đăng nhập không hợp lệ";
      } else if (e.code == 'operation-not-allowed') {
        message = "Đăng nhập Google chưa được bật";
      } else if (e.code == 'user-disabled') {
        message = "Tài khoản đã bị vô hiệu hóa";
      } else if (e.code == 'user-not-found') {
        message = "Không tìm thấy tài khoản";
      } else if (e.code == 'invalid-verification-code') {
        message = "Mã xác thực không hợp lệ";
      } else if (e.code == 'invalid-verification-id') {
        message = "ID xác thực không hợp lệ";
      }
      Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
      );
      return null;
    } catch (e) {
      return null;
    }
  }

  // Đăng ký với email và password


  // Đăng xuất
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      Fluttertoast.showToast(
        msg: "Đăng xuất thành công!",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Có lỗi khi đăng xuất: $e",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
      );
    }
  }

  // Gửi email reset password
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      Fluttertoast.showToast(
        msg: "Email reset password đã được gửi!",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
      );
    } on FirebaseAuthException catch (e) {
      String message = "Gửi email thất bại";
      if (e.code == 'user-not-found') {
        message = "Không tìm thấy tài khoản với email này";
      } else if (e.code == 'invalid-email') {
        message = "Email không hợp lệ";
      }
      Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Có lỗi xảy ra: $e",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
      );
    }
  }
} 