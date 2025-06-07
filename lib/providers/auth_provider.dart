import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null;
  String? get errorMessage => _errorMessage;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> checkAuthState() async {
    try {
      final User? firebaseUser = _auth.currentUser;
      if (firebaseUser != null) {
        await _loadUserData(firebaseUser.uid);
      }
    } catch (e) {
      debugPrint('Check auth state error: $e');
    }
  }

  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Create Firebase Auth user
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        // Create user model
        final userModel = UserModel(
          id: result.user!.uid,
          name: name,
          email: email,
          role: role,
          createdAt: DateTime.now(),
        );

        // Save to Firestore
        await _firestore
            .collection('users')
            .doc(result.user!.uid)
            .set(userModel.toMap());

        _user = userModel;
        debugPrint('User created successfully: ${_user?.name}');
        return true;
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException: ${e.code} - ${e.message}');
      
      switch (e.code) {
        case 'weak-password':
          _errorMessage = 'Password terlalu lemah (minimal 6 karakter)';
          break;
        case 'email-already-in-use':
          _errorMessage = 'Email sudah terdaftar. Silakan login.';
          break;
        case 'invalid-email':
          _errorMessage = 'Format email tidak valid';
          break;
        case 'operation-not-allowed':
          _errorMessage = 'Registrasi tidak diizinkan. Hubungi admin.';
          break;
        case 'network-request-failed':
          _errorMessage = 'Koneksi internet bermasalah';
          break;
        default:
          _errorMessage = 'Registrasi gagal: ${e.message}';
      }
    } catch (e) {
      debugPrint('General sign up error: $e');
      _errorMessage = 'Terjadi kesalahan tidak terduga';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  Future<bool> signIn({required String email, required String password}) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        await _loadUserData(result.user!.uid);
        debugPrint('User signed in successfully: ${_user?.name}');
        return true;
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException: ${e.code} - ${e.message}');
      
      switch (e.code) {
        case 'user-not-found':
          _errorMessage = 'Email tidak terdaftar';
          break;
        case 'wrong-password':
          _errorMessage = 'Password salah';
          break;
        case 'invalid-email':
          _errorMessage = 'Format email tidak valid';
          break;
        case 'user-disabled':
          _errorMessage = 'Akun telah dinonaktifkan';
          break;
        case 'too-many-requests':
          _errorMessage = 'Terlalu banyak percobaan. Coba lagi nanti.';
          break;
        case 'network-request-failed':
          _errorMessage = 'Koneksi internet bermasalah';
          break;
        default:
          _errorMessage = 'Login gagal: ${e.message}';
      }
    } catch (e) {
      debugPrint('General sign in error: $e');
      _errorMessage = 'Terjadi kesalahan tidak terduga';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  Future<void> _loadUserData(String uid) async {
    try {
      final DocumentSnapshot doc = 
          await _firestore.collection('users').doc(uid).get();
      
      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        _user = UserModel.fromMap({
          'id': doc.id,
          ...data,
        });
        debugPrint('User data loaded: ${_user?.name}');
      } else {
        // Jika data tidak ada di Firestore, buat dari Firebase Auth
        final currentUser = _auth.currentUser;
        if (currentUser != null) {
          _user = UserModel(
            id: currentUser.uid,
            name: currentUser.displayName ?? 'User',
            email: currentUser.email ?? '',
            role: UserRole.orangtua, // Default
            createdAt: DateTime.now(),
          );
          
          // Save to Firestore
          await _firestore
              .collection('users')
              .doc(currentUser.uid)
              .set(_user!.toMap());
          
          debugPrint('Created user data from Auth: ${_user?.name}');
        }
      }
    } catch (e) {
      debugPrint('Load user data error: $e');
      _errorMessage = 'Gagal memuat data pengguna';
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _user = null;
      _errorMessage = null;
      notifyListeners();
      debugPrint('User signed out');
    } catch (e) {
      _errorMessage = 'Gagal logout';
      debugPrint('Sign out error: $e');
      notifyListeners();
    }
  }

  Future<bool> resetPassword(String email) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _auth.sendPasswordResetEmail(email: email);
      
      return true;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          _errorMessage = 'Email tidak terdaftar';
          break;
        case 'invalid-email':
          _errorMessage = 'Format email tidak valid';
          break;
        case 'network-request-failed':
          _errorMessage = 'Koneksi internet bermasalah';
          break;
        default:
          _errorMessage = 'Gagal mengirim email reset: ${e.message}';
      }
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan tidak terduga';
      debugPrint('Reset password error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  // Update user profile
  Future<bool> updateProfile({
    required String name,
    UserRole? role,
  }) async {
    try {
      if (_user == null) return false;

      _isLoading = true;
      notifyListeners();

      final updatedUser = _user!.copyWith(
        name: name,
        role: role ?? _user!.role,
      );

      await _firestore
          .collection('users')
          .doc(_user!.id)
          .update(updatedUser.toMap());

      _user = updatedUser;
      debugPrint('Profile updated: ${_user?.name}');
      return true;
    } catch (e) {
      _errorMessage = 'Gagal update profil';
      debugPrint('Update profile error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}