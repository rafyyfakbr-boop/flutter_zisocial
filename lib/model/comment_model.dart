import 'package:zisocial/core/constant.dart';

class CommentAuthor {
  final int id;
  final String username;
  final String name;
  final String avatar;

  CommentAuthor({
    required this.id,
    required this.username,
    required this.name,
    required this.avatar,
  });

  factory CommentAuthor.fromJson(Map<String, dynamic> json) {
    return CommentAuthor(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      username: json['username']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      avatar: json['avatar']?.toString() ?? '',
    );
  }

  String get fullAvatarUrl => ApiConstants.getImageUrl(avatar);
}

class CommentModel {
  final int id;
  final int userId;
  final int postId;
  final String text;
  final String createDate;
  final CommentAuthor? author;

  CommentModel({
    required this.id,
    required this.userId,
    required this.postId,
    required this.text,
    required this.createDate,
    this.author,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      userId: int.tryParse(json['user_id']?.toString() ?? '0') ?? 0,
      postId: int.tryParse(json['post_id']?.toString() ?? '0') ?? 0,
      text: json['text']?.toString() ?? '',
      createDate: json['create_date']?.toString() ?? '',
      author: json['author'] != null && json['author'] is Map<String, dynamic>
          ? CommentAuthor.fromJson(json['author'])
          : null,
    );
  }

  String get formattedTime {
    if (createDate.isEmpty) return 'Baru saja';
    try {
      final date = DateTime.parse(createDate);
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inMinutes < 1) {
        return 'Baru saja';
      } else if (diff.inMinutes < 60) {
        return '${diff.inMinutes}m';
      } else if (diff.inHours < 24) {
        return '${diff.inHours}j';
      } else if (diff.inDays < 7) {
        return '${diff.inDays}h';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (_) {
      return createDate;
    }
  }
}
