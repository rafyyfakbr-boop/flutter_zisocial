import 'package:zisocial/core/constant.dart';

class ConversationModel {
  final int partnerId;
  final String partnerUsername;
  final String partnerName;
  final String partnerAvatar;
  final String partnerBio;
  final String lastMessage;
  final int lastSenderId;
  final String lastTime;
  int unreadCount;

  ConversationModel({
    required this.partnerId,
    required this.partnerUsername,
    required this.partnerName,
    required this.partnerAvatar,
    required this.partnerBio,
    required this.lastMessage,
    required this.lastSenderId,
    required this.lastTime,
    this.unreadCount = 0,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      partnerId: int.tryParse(json['partner_id']?.toString() ?? '0') ?? 0,
      partnerUsername: json['partner_username']?.toString() ?? '',
      partnerName: json['partner_name']?.toString() ?? '',
      partnerAvatar: json['partner_avatar']?.toString() ?? '',
      partnerBio: json['partner_bio']?.toString() ?? '',
      lastMessage: json['last_message']?.toString() ?? '',
      lastSenderId:
          int.tryParse(json['last_sender_id']?.toString() ?? '0') ?? 0,
      lastTime: json['last_time']?.toString() ?? '',
      unreadCount: int.tryParse(json['unread_count']?.toString() ?? '0') ?? 0,
    );
  }

  String get fullAvatarUrl => ApiConstants.getImageUrl(partnerAvatar);

  String get formattedTime {
    if (lastTime.isEmpty) return '';
    try {
      final date = DateTime.parse(lastTime);
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inMinutes < 1) return 'Baru saja';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m';
      if (diff.inHours < 24) return '${diff.inHours}j';
      if (diff.inDays < 7) return '${diff.inDays}h';
      return '${date.day}/${date.month}';
    } catch (_) {
      return '';
    }
  }
}

class DirectMessageModel {
  final int id;
  final int senderId;
  final int receiverId;
  final String text;
  final bool isRead;
  final String createDate;

  DirectMessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.isRead,
    required this.createDate,
  });

  factory DirectMessageModel.fromJson(Map<String, dynamic> json) {
    return DirectMessageModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      senderId: int.tryParse(json['sender_id']?.toString() ?? '0') ?? 0,
      receiverId: int.tryParse(json['receiver_id']?.toString() ?? '0') ?? 0,
      text: json['text']?.toString() ?? '',
      isRead: json['is_read'] == true || json['is_read']?.toString() == '1',
      createDate: json['create_date']?.toString() ?? '',
    );
  }

  String get formattedHour {
    if (createDate.isEmpty) return '';
    try {
      final date = DateTime.parse(createDate);
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }
}

