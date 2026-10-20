import 'package:flutter/foundation.dart';
import 'package:zisocial/core/constant.dart';
import 'package:zisocial/core/network.dart';

class RegisterViewModel extends ChangeNotifier {
  final ApiClient _apiClient;

  RegisterViewModel(this._apiClient);

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  Future<bool> register({
    required String name,
    required String username,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;

    notifyListeners();

    try {
      final response = await _apiClient.post(
        ApiConstants.register,
        body: {
          'name': name,
          'username': username,
          'email': email,
          'password': password,
        },
      );

      _successMessage = response['message'];

      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst(
        'Exception: ',
        '',
      );

      return false;
    } finally {
      _isLoading = false;

      notifyListeners();
    }
  }
}