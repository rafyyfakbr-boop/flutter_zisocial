import 'package:flutter/foundation.dart';
import 'package:zisocial/core/constant.dart';
import 'package:zisocial/core/network.dart';

class CreatePostViewModel extends ChangeNotifier {
  final ApiClient _apiClient;

  CreatePostViewModel(this._apiClient);

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  Future<bool> createPost({
    required int userId,
    required String imagePath,
    String caption = '',
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;

    notifyListeners();

    try {
      final response = await _apiClient.upload(
        ApiConstants.createPost,
        filePath: imagePath,
        fieldName: 'image',
        fields: {
          'user_id': userId.toString(),
          'caption': caption,
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