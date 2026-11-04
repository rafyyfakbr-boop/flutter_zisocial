import 'package:flutter/foundation.dart';
import 'package:zisocial/core/constant.dart';
import 'package:zisocial/core/network.dart';
import 'package:zisocial/model/message_model.dart';

class MessageViewModel extends ChangeNotifier {
  final ApiClient _apiClient;

  MessageViewModel(this._apiClient);

  List<ConversationModel> _conversations = [];
  bool _isLoadingConversations = false;

  // Cache pesan per partnerId
  final Map<int, List<DirectMessageModel>> _messagesByPartner = {};
  final Set<int> _loadingChatPartners = {};

  List<ConversationModel> get conversations => _conversations;
  bool get isLoadingConversations => _isLoadingConversations;

  int get totalUnreadCount =>
      _conversations.fold(0, (sum, c) => sum + c.unreadCount);

  List<DirectMessageModel> getMessages(int partnerId) =>
      _messagesByPartner[partnerId] ?? [];

  bool isLoadingChat(int partnerId) =>
      _loadingChatPartners.contains(partnerId);

  Future<void> fetchConversations(int userId, {bool silent = false}) async {
    if (userId <= 0) return;
    if (!silent) {
      _isLoadingConversations = true;
      notifyListeners();
    }

    try {
      final response = await _apiClient.get(
        '${ApiConstants.getConversations}?user_id=$userId',
      );
      final raw = response['data'];
      if (raw is List) {
        _conversations = raw
            .whereType<Map>()
            .map((e) => ConversationModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      } else {
        _conversations = [];
      }
    } catch (_) {
      // Biarkan daftar sebelumnya jika gagal
    } finally {
      _isLoadingConversations = false;
      notifyListeners();
    }
  }

  Future<void> fetchMessages(
    int userId,
    int partnerId, {
    bool silent = false,
  }) async {
    if (userId <= 0 || partnerId <= 0) return;
    if (!silent) {
      _loadingChatPartners.add(partnerId);
      notifyListeners();
    }

    try {
      final response = await _apiClient.get(
        '${ApiConstants.readMessages}?user_id=$userId&partner_id=$partnerId',
      );
      final raw = response['data'];
      if (raw is List) {
        _messagesByPartner[partnerId] = raw
            .whereType<Map>()
            .map((e) =>
                DirectMessageModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }

      // Reset unread count di daftar percakapan
      for (final conv in _conversations) {
        if (conv.partnerId == partnerId) {
          conv.unreadCount = 0;
        }
      }
    } catch (_) {
      // Abaikan jika gagal
    } finally {
      _loadingChatPartners.remove(partnerId);
      notifyListeners();
    }
  }

  Future<bool> sendMessage({
    required int senderId,
    required int receiverId,
    required String text,
    String partnerUsername = '',
    String partnerName = '',
    String partnerAvatar = '',
    String partnerBio = '',
  }) async {
    final trimmed = text.trim();
    if (senderId <= 0 || receiverId <= 0 || trimmed.isEmpty) return false;

    // Optimistic message
    final tempMsg = DirectMessageModel(
      id: DateTime.now().millisecondsSinceEpoch,
      senderId: senderId,
      receiverId: receiverId,
      text: trimmed,
      isRead: false,
      createDate: DateTime.now().toIso8601String(),
    );

    final list = List<DirectMessageModel>.from(
      _messagesByPartner[receiverId] ?? const [],
    )..add(tempMsg);
    _messagesByPartner[receiverId] = list;
    notifyListeners();

    try {
      final response = await _apiClient.post(
        ApiConstants.sendMessage,
        body: {
          'sender_id': senderId,
          'receiver_id': receiverId,
          'text': trimmed,
        },
      );

      if (response['data'] is Map) {
        final realMsg = DirectMessageModel.fromJson(
          Map<String, dynamic>.from(response['data'] as Map),
        );
        final updated = List<DirectMessageModel>.from(
          _messagesByPartner[receiverId] ?? const [],
        );
        final idx = updated.indexWhere((m) => m.id == tempMsg.id);
        if (idx != -1) {
          updated[idx] = realMsg;
          _messagesByPartner[receiverId] = updated;
        }
      }

      // Perbarui daftar conversations secara lokal
      fetchConversations(senderId, silent: true);
      return true;
    } catch (_) {
      // Rollback jika gagal
      final updated = List<DirectMessageModel>.from(
        _messagesByPartner[receiverId] ?? const [],
      )..removeWhere((m) => m.id == tempMsg.id);
      _messagesByPartner[receiverId] = updated;
      notifyListeners();
      return false;
    }
  }
}

