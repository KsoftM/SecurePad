import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/auth/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _user;
  bool _loading = true;

  AuthProvider() {
    _authService.userChanges.listen((user) {
      _user = user;
      _loading = false;
      notifyListeners();
    });
  }

  User? get user => _user;
  bool get isLoading => _loading;
  bool get isAuthenticated => _user != null;

  Future<void> signIn(String email, String password) async {
    _loading = true;
    notifyListeners();
    await _authService.signInWithEmail(email, password);
  }

  Future<void> register(String email, String password) async {
    _loading = true;
    notifyListeners();
    await _authService.registerWithEmail(email, password);
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }
}
