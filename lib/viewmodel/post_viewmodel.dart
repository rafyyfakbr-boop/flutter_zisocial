import 'package:flutter/foundation.dart';
import 'package:zisocial/core/constant.dart';
import 'package:zisocial/core/network.dart';
import 'package:zisocial/model/post_model.dart';

class PostViewModel extends ChangeNotifier {
  final ApiClient _apiClient;

  PostViewModel(this._apiClient);

  List<PostModel> _posts = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<PostModel> get posts => _posts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  bool get isEmpty => _posts.isEmpty && !_isLoading && _errorMessage == null;

  Future<void> fetchPosts({bool isRefresh = false, int? userId}) async {
    if (!isRefresh) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      // Kirim user_id sebagai query param agar backend bisa menentukan is_liked
      final url = userId != null && userId != 0
          ? '${ApiConstants.readPosts}?user_id=$userId'
          : ApiConstants.readPosts;
      final response = await _apiClient.get(url);

      if (response.containsKey('data') && response['data'] is List) {
        final List<dynamic> dataList = response['data'];
        _posts = dataList.map((item) => PostModel.fromJson(item)).toList();
        _errorMessage = null;
      } else {
        _posts = [];
      }
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Like / Unlike ──────────────────────────────────────────────────────────
  Future<void> toggleLike(int postId, int userId) async {
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index == -1) return;

    final post = _posts[index];
    final wasLiked = post.isLiked;

    // Optimistic update
    post.isLiked = !wasLiked;
    post.likeCount += post.isLiked ? 1 : -1;
    if (post.likeCount < 0) post.likeCount = 0;
    notifyListeners();

    try {
      // Backend toggle.php otomatis like/unlike berdasarkan status saat ini
      await _apiClient.post(
        ApiConstants.toggleLike,
        body: {'user_id': userId, 'post_id': postId},
      );
    } catch (_) {
      // Rollback jika gagal
      post.isLiked = wasLiked;
      post.likeCount += wasLiked ? 1 : -1;
      if (post.likeCount < 0) post.likeCount = 0;
      notifyListeners();
    }
  }

  // ── Hapus Postingan ────────────────────────────────────────────────────────
  Future<bool> deletePost(int postId, int userId) async {
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index == -1) return false;

    // Optimistic remove
    final removed = _posts.removeAt(index);
    notifyListeners();

    try {
      await _apiClient.post(
        ApiConstants.deletePost,
        body: {'post_id': postId, 'user_id': userId},
      );
      return true;
    } catch (_) {
      // Rollback jika gagal
      _posts.insert(index, removed);
      notifyListeners();
      return false;
    }
  }

  // ── Edit Postingan ─────────────────────────────────────────────────────────
  Future<bool> updatePost({
    required int postId,
    required int userId,
    required String caption,
  }) async {
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index == -1) return false;

    final oldCaption = _posts[index].caption;

    // Optimistic update
    _posts[index] = PostModel(
      id: _posts[index].id,
      caption: caption,
      image: _posts[index].image,
      createDate: _posts[index].createDate,
      updatedDate: DateTime.now().toIso8601String(),
      author: _posts[index].author,
      likeCount: _posts[index].likeCount,
      commentCount: _posts[index].commentCount,
      isLiked: _posts[index].isLiked,
      isSaved: _posts[index].isSaved,
    );
    notifyListeners();

    try {
      await _apiClient.post(
        ApiConstants.updatePost,
        body: {'post_id': postId, 'user_id': userId, 'caption': caption},
      );
      return true;
    } catch (_) {
      // Rollback
      _posts[index] = PostModel(
        id: _posts[index].id,
        caption: oldCaption,
        image: _posts[index].image,
        createDate: _posts[index].createDate,
        updatedDate: _posts[index].updatedDate,
        author: _posts[index].author,
        likeCount: _posts[index].likeCount,
        commentCount: _posts[index].commentCount,
        isLiked: _posts[index].isLiked,
        isSaved: _posts[index].isSaved,
      );
      notifyListeners();
      return false;
    }
  }

  // ── Save / Bookmark (Server + Optimistic) ──────────────────────────────────
  Future<void> toggleSave(int postId, int userId) async {
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index == -1) return;

    final post = _posts[index];
    final wasSaved = post.isSaved;

    // Optimistic update
    post.isSaved = !wasSaved;
    notifyListeners();

    if (userId <= 0) return;

    try {
      await _apiClient.post(
        ApiConstants.toggleSave,
        body: {'user_id': userId, 'post_id': postId},
      );
    } catch (_) {
      // Rollback jika gagal
      post.isSaved = wasSaved;
      notifyListeners();
    }
  }

  void updateCommentCount(int postId, int delta) {
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index != -1) {
      _posts[index].commentCount += delta;
      if (_posts[index].commentCount < 0) _posts[index].commentCount = 0;
      notifyListeners();
    }
  }

  /// Sinkronkan informasi author pada seluruh post di memori setelah user edit profil
  void syncAuthorInfo({
    required int userId,
    required String name,
    required String username,
    required String avatar,
  }) {
    bool changed = false;
    for (var i = 0; i < _posts.length; i++) {
      final post = _posts[i];
      if (post.author?.id == userId) {
        _posts[i] = PostModel(
          id: post.id,
          caption: post.caption,
          image: post.image,
          createDate: post.createDate,
          updatedDate: post.updatedDate,
          author: AuthorModel(
            id: userId,
            username: username,
            name: name,
            avatar: avatar,
          ),
          likeCount: post.likeCount,
          commentCount: post.commentCount,
          isLiked: post.isLiked,
          isSaved: post.isSaved,
        );
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }
}
