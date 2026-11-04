import 'package:zisocial/core/constant.dart';

class AuthorModel {
  final int id;
  final String username;
  final String name;
  final String avatar;

  AuthorModel({
    required this.id,
    required this.username,
    required this.name,
    required this.avatar,
  });

  factory AuthorModel.fromJson(Map<String, dynamic> json) {
    return AuthorModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      username: json['username']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      avatar: json['avatar']?.toString() ?? '',
    );
  }

  String get fullAvatarUrl => ApiConstants.getImageUrl(avatar);
}

class PostModel {
  final int id;
  final String caption;
  final String image;
  final String createDate;
  final String updatedDate;
  final AuthorModel? author;
  int likeCount;
  int commentCount;
  bool isLiked;
  bool isSaved;

  PostModel({
    required this.id,
    required this.caption,
    required this.image,
    required this.createDate,
    required this.updatedDate,
    this.author,
    this.likeCount = 0,
    this.commentCount = 0,
    this.isLiked = false,
    this.isSaved = false,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    // Parse is_liked: bisa berupa bool, int (0/1), atau string ("0"/"1"/"true"/"false")
    bool parsedIsLiked = false;
    final rawLiked = json['is_liked'];
    if (rawLiked is bool) {
      parsedIsLiked = rawLiked;
    } else if (rawLiked is int) {
      parsedIsLiked = rawLiked == 1;
    } else if (rawLiked is String) {
      parsedIsLiked = rawLiked == '1' || rawLiked.toLowerCase() == 'true';
    }

    bool parsedIsSaved = false;
    final rawSaved = json['is_saved'];
    if (rawSaved is bool) {
      parsedIsSaved = rawSaved;
    } else if (rawSaved is int) {
      parsedIsSaved = rawSaved == 1;
    } else if (rawSaved is String) {
      parsedIsSaved = rawSaved == '1' || rawSaved.toLowerCase() == 'true';
    }

    return PostModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      caption: json['caption']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
      createDate: json['create_date']?.toString() ?? '',
      updatedDate: json['updated_date']?.toString() ?? '',
      author: json['author'] != null && json['author'] is Map<String, dynamic>
          ? AuthorModel.fromJson(json['author'])
          : null,
      likeCount: int.tryParse(json['like_count']?.toString() ?? '0') ?? 0,
      commentCount: int.tryParse(json['comment_count']?.toString() ?? '0') ?? 0,
      isLiked: parsedIsLiked,
      isSaved: parsedIsSaved,
    );
  }

  String get fullImageUrl => ApiConstants.getImageUrl(image);

  String get formattedTime {
    if (createDate.isEmpty) return '';
    try {
      final date = DateTime.parse(createDate);
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inMinutes < 1) {
        return 'BARU SAJA';
      } else if (diff.inMinutes < 60) {
        return '${diff.inMinutes} MENIT LALU';
      } else if (diff.inHours < 24) {
        return '${diff.inHours} JAM LALU';
      } else if (diff.inDays < 7) {
        return '${diff.inDays} HARI LALU';
      } else {
        return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
      }
    } catch (_) {
      return createDate.toUpperCase();
    }
  }
}
