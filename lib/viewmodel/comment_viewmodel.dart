import 'package:flutter/foundation.dart';
import 'package:zisocial/core/constant.dart';
import 'package:zisocial/core/network.dart';
import 'package:zisocial/model/comment_model.dart';
import 'package:zisocial/model/user_model.dart';

class CommentViewModel extends ChangeNotifier {
  final ApiClient _apiClient;

  CommentViewModel(this._apiClient);

  final Map<int, List<CommentModel>> _commentsByPost = {};
  final Set<int> _loadingPostIds = {};
  bool _isSubmitting = false;
  String? _errorMessage;

  bool isPostLoading(int postId) => _loadingPostIds.contains(postId);
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

  List<CommentModel> getComments(int postId) => _commentsByPost[postId] ?? [];

  Future<void> fetchComments(int postId) async {
    _loadingPostIds.add(postId);
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.get(
        '${ApiConstants.readComments}?post_id=$postId',
      );

      if (response.containsKey('data') && response['data'] is List) {
        final List<dynamic> dataList = response['data'];
        _commentsByPost[postId] = dataList
            .map((item) => CommentModel.fromJson(item))
            .toList();
      } else {
        _commentsByPost[postId] ??= [];
      }
    } catch (e) {
      _commentsByPost[postId] ??= [];
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _loadingPostIds.remove(postId);
      notifyListeners();
    }
  }

  Future<bool> addComment({
    required int postId,
    required int userId,
    required String text,
    UserModel? currentUser,
  }) async {
    if (text.trim().isEmpty) return false;

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    final newComment = CommentModel(
      id: DateTime.now().millisecondsSinceEpoch,
      userId: userId,
      postId: postId,
      text: text.trim(),
      createDate: DateTime.now().toIso8601String(),
      author: currentUser != null
          ? CommentAuthor(
              id: int.tryParse(currentUser.id) ?? userId,
              username: currentUser.username,
              name: currentUser.name,
              avatar: currentUser.avatar,
            )
          : null,
    );

    _commentsByPost[postId] = [...(_commentsByPost[postId] ?? []), newComment];
    notifyListeners();

    try {
      await _apiClient.post(
        ApiConstants.createComment,
        body: {'user_id': userId, 'post_id': postId, 'text': text.trim()},
      );
      return true;
    } catch (e) {
      return true;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> deleteComment({
    required int commentId,
    required int postId,
  }) async {
    final currentList = _commentsByPost[postId] ?? [];
    _commentsByPost[postId] = currentList
        .where((c) => c.id != commentId)
        .toList();
    notifyListeners();

    try {
      await _apiClient.post(
        ApiConstants.deleteComment,
        body: {'comment_id': commentId},
      );
      return true;
    } catch (_) {
      return true;
    }
  }
}
