import 'package:flutter/foundation.dart';
import 'package:zisocial/core/constant.dart';
import 'package:zisocial/core/network.dart';
import 'package:zisocial/model/follow_model.dart';

class FollowViewModel extends ChangeNotifier {
  final ApiClient _apiClient;

  FollowViewModel(this._apiClient);

  // Cache stats per userId
  final Map<int, FollowStatsModel> _stats = {};
  final Set<int> _loadingIds = {};
  // Target yang request follow/unfollow-nya sedang berjalan (cegah double tap)
  final Set<int> _pendingIds = {};

  FollowStatsModel? getStats(int userId) => _stats[userId];
  bool isLoading(int userId) => _loadingIds.contains(userId);
  bool isPending(int userId) => _pendingIds.contains(userId);

  /// Ambil stats followers/following + status isFollowing untuk [targetUserId]
  /// dilihat dari sudut pandang [viewerId].
  Future<void> fetchStats(int targetUserId, int viewerId) async {
    _loadingIds.add(targetUserId);
    notifyListeners();

    try {
      final response = await _apiClient.get(
        '${ApiConstants.getFollowStats}?user_id=$targetUserId&viewer_id=$viewerId',
      );
      _stats[targetUserId] = FollowStatsModel.fromJson(response);
    } catch (_) {
      // Jika gagal, jangan timpa data lama yang sudah ada
      _stats[targetUserId] ??= FollowStatsModel(
        followersCount: 0,
        followingCount: 0,
        isFollowing: false,
      );
    } finally {
      _loadingIds.remove(targetUserId);
      notifyListeners();
    }
  }

  /// Ambil daftar user. [type] = 'followers' atau 'following'.
  /// Status isFollowing tiap user ikut disimpan ke cache agar tombol sinkron.
  Future<List<FollowUserModel>> fetchFollowList(
    int userId,
    int viewerId, {
    required String type,
  }) async {
    final response = await _apiClient.get(
      '${ApiConstants.getFollowList}?user_id=$userId&viewer_id=$viewerId&type=$type',
    );
    final raw = response['data'];
    if (raw is! List) return [];

    final users = <FollowUserModel>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);
      final user = FollowUserModel.fromJson(map);
      users.add(user);

      final isFollowing = map['is_following'] == true ||
          map['is_following']?.toString() == '1';
      final current = _stats[user.id];
      _stats[user.id] = FollowStatsModel(
        followersCount: current?.followersCount ?? 0,
        followingCount: current?.followingCount ?? 0,
        isFollowing: isFollowing,
      );
    }
    notifyListeners();
    return users;
  }

  /// Cari pengguna berdasarkan kata kunci [query] (nama / username).
  Future<List<FollowUserModel>> searchUsers(
    String query,
    int viewerId,
  ) async {
    final encoded = Uri.encodeQueryComponent(query.trim());
    final response = await _apiClient.get(
      '${ApiConstants.searchUsers}?q=$encoded&viewer_id=$viewerId',
    );
    final raw = response['data'];
    if (raw is! List) return [];

    final users = <FollowUserModel>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);
      final user = FollowUserModel.fromJson(map);
      users.add(user);

      final isFollowing = map['is_following'] == true ||
          map['is_following']?.toString() == '1';
      final current = _stats[user.id];
      _stats[user.id] = FollowStatsModel(
        followersCount: current?.followersCount ?? 0,
        followingCount: current?.followingCount ?? 0,
        isFollowing: isFollowing,
      );
    }
    notifyListeners();
    return users;
  }

  /// Update angka "following" milik user yang login secara lokal.
  void _adjustOwnFollowing(int followerId, int delta) {
    final own = _stats[followerId];
    if (own == null) return;
    _stats[followerId] = FollowStatsModel(
      followersCount: own.followersCount,
      followingCount: (own.followingCount + delta) < 0
          ? 0
          : own.followingCount + delta,
      isFollowing: own.isFollowing,
    );
  }

  /// Follow [targetUserId] oleh [followerId].
  Future<void> follow(int targetUserId, int followerId) async {
    // Optimistic update
    final current = _stats[targetUserId];
    _stats[targetUserId] = FollowStatsModel(
      followersCount: (current?.followersCount ?? 0) + 1,
      followingCount: current?.followingCount ?? 0,
      isFollowing: true,
    );
    _adjustOwnFollowing(followerId, 1);
    notifyListeners();

    try {
      await _apiClient.post(
        ApiConstants.followUser,
        body: {'follower_id': followerId, 'following_id': targetUserId},
      );
    } catch (_) {
      // Rollback
      _stats[targetUserId] = FollowStatsModel(
        followersCount: (current?.followersCount ?? 0),
        followingCount: current?.followingCount ?? 0,
        isFollowing: false,
      );
      _adjustOwnFollowing(followerId, -1);
      notifyListeners();
    }
  }

  /// Unfollow [targetUserId] oleh [followerId].
  Future<void> unfollow(int targetUserId, int followerId) async {
    final current = _stats[targetUserId];
    _stats[targetUserId] = FollowStatsModel(
      followersCount: ((current?.followersCount ?? 1) - 1) < 0
          ? 0
          : (current?.followersCount ?? 1) - 1,
      followingCount: current?.followingCount ?? 0,
      isFollowing: false,
    );
    _adjustOwnFollowing(followerId, -1);
    notifyListeners();

    try {
      await _apiClient.post(
        ApiConstants.unfollowUser,
        body: {'follower_id': followerId, 'following_id': targetUserId},
      );
    } catch (_) {
      // Rollback
      _stats[targetUserId] = FollowStatsModel(
        followersCount: current?.followersCount ?? 0,
        followingCount: current?.followingCount ?? 0,
        isFollowing: true,
      );
      _adjustOwnFollowing(followerId, 1);
      notifyListeners();
    }
  }

  /// Toggle follow/unfollow
  Future<void> toggleFollow(int targetUserId, int followerId) async {
    if (_pendingIds.contains(targetUserId)) return;
    _pendingIds.add(targetUserId);
    try {
      final stats = _stats[targetUserId];
      if (stats?.isFollowing == true) {
        await unfollow(targetUserId, followerId);
      } else {
        await follow(targetUserId, followerId);
      }
    } finally {
      _pendingIds.remove(targetUserId);
    }
  }
}
