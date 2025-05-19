import 'package:flutter/material.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void setErrorMessage(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    setLoading(true);
    setErrorMessage(null);
    
    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));
    
    // For demo purposes - validate email format
    if (!_isValidEmail(email)) {
      setErrorMessage('Email format is invalid');
      setLoading(false);
      return false;
    }
    
    // For demo purposes - validate password
    if (password.length < 6) {
      setErrorMessage('Password should be at least 6 characters');
      setLoading(false);
      return false;
    }
    
    setLoading(false);
    return true;
  }

  Future<bool> register(String name, String email, String password) async {
    setLoading(true);
    setErrorMessage(null);
    
    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));
    
    // For demo purposes - validate name
    if (name.isEmpty) {
      setErrorMessage('Name cannot be empty');
      setLoading(false);
      return false;
    }
    
    // For demo purposes - validate email format
    if (!_isValidEmail(email)) {
      setErrorMessage('Email format is invalid');
      setLoading(false);
      return false;
    }
    
    // For demo purposes - validate password
    if (password.length < 6) {
      setErrorMessage('Password should be at least 6 characters');
      setLoading(false);
      return false;
    }
    
    setLoading(false);
    return true;
  }

  Future<bool> resetPassword(String email) async {
    setLoading(true);
    setErrorMessage(null);
    
    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));
    
    // For demo purposes - validate email format
    if (!_isValidEmail(email)) {
      setErrorMessage('Email format is invalid');
      setLoading(false);
      return false;
    }
    
    setLoading(false);
    return true;
  }

  bool _isValidEmail(String email) {
    final emailRegExp = RegExp(r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+');
    return emailRegExp.hasMatch(email);
  }
}