import 'package:flutter/foundation.dart';
import 'package:zisocial/core/constant.dart';
import 'package:zisocial/core/network.dart';
import 'package:zisocial/model/user_model.dart';

class LoginViewModel extends ChangeNotifier {
  final ApiClient _apiClient;

  LoginViewModel(this._apiClient);

  bool _isLoading = false;
  String? _errorMessage;
  UserModel? _user;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  UserModel? get user => _user;

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;

    notifyListeners();

    try {
      final response = await _apiClient.post(
        ApiConstants.login,
        body: {
          'email': email,
          'password': password,
        },
      );
      _user = UserModel.fromJson(response['user']);
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

  /// Update foto profil, nama, username, dan bio.
  Future<bool> updateProfile({
    required String name,
    required String username,
    String? bio,
    String? avatarFilePath,
    Uint8List? avatarBytes,
    String? avatarFileName,
  }) async {
    final currentUser = _user;
    if (currentUser == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      Map<String, dynamic> response;

      if ((avatarFilePath != null && avatarFilePath.isNotEmpty) ||
          avatarBytes != null) {
        response = await _apiClient.upload(
          ApiConstants.updateProfile,
          filePath: avatarFilePath ?? '',
          fileBytes: avatarBytes,
          fileName: avatarFileName,
          fieldName: 'avatar',
          fields: {
            'user_id': currentUser.id,
            'name': name,
            'username': username,
            if (bio != null) 'bio': bio,
          },
        );
      } else {
        response = await _apiClient.post(
          ApiConstants.updateProfile,
          body: {
            'user_id': currentUser.id,
            'name': name,
            'username': username,
            if (bio != null) 'bio': bio,
          },
        );
      }

      if (response['user'] is Map<String, dynamic>) {
        _user = UserModel.fromJson(response['user'] as Map<String, dynamic>);
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void logout() {
    _user = null;
    notifyListeners();
  }
}
