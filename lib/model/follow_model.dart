import 'package:zisocial/core/constant.dart';

/// User yang muncul di daftar Followers / Following.
class FollowUserModel {
  final int id;
  final String username;
  final String name;
  final String avatar;
  final String bio;

  FollowUserModel({
    required this.id,
    required this.username,
    required this.name,
    required this.avatar,
    required this.bio,
  });

  factory FollowUserModel.fromJson(Map<String, dynamic> json) {
    return FollowUserModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      username: json['username']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      avatar: json['avatar']?.toString() ?? '',
      bio: json['bio']?.toString() ?? '',
    );
  }

  String get fullAvatarUrl => ApiConstants.getImageUrl(avatar);
}

class FollowModel {
  final int id;
  final int followerId;
  final int followingId;
  final String followerUsername;
  final String followerName;
  final String followerAvatar;

  FollowModel({
    required this.id,
    required this.followerId,
    required this.followingId,
    required this.followerUsername,
    required this.followerName,
    required this.followerAvatar,
  });

  factory FollowModel.fromJson(Map<String, dynamic> json) {
    return FollowModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      followerId: int.tryParse(json['follower_id']?.toString() ?? '0') ?? 0,
      followingId: int.tryParse(json['following_id']?.toString() ?? '0') ?? 0,
      followerUsername: json['follower_username']?.toString() ?? '',
      followerName: json['follower_name']?.toString() ?? '',
      followerAvatar: json['follower_avatar']?.toString() ?? '',
    );
  }
}

class FollowStatsModel {
  final int followersCount;
  final int followingCount;
  final bool isFollowing;

  FollowStatsModel({
    required this.followersCount,
    required this.followingCount,
    required this.isFollowing,
  });

  factory FollowStatsModel.fromJson(Map<String, dynamic> json) {
    final map = (json['data'] is Map<String, dynamic>)
        ? json['data'] as Map<String, dynamic>
        : json;
    return FollowStatsModel(
      followersCount:
          int.tryParse(map['followers_count']?.toString() ?? '0') ?? 0,
      followingCount:
          int.tryParse(map['following_count']?.toString() ?? '0') ?? 0,
      isFollowing:
          map['is_following'] == true || map['is_following']?.toString() == '1',
    );
  }
}
