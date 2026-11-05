import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:zisocial/core/constant.dart';
import 'package:zisocial/core/network.dart';
import 'package:zisocial/model/message_model.dart';

class MessageViewModel extends ChangeNotifier {
  final ApiClient _apiClient;
  final PusherChannelsFlutter _pusher = PusherChannelsFlutter.getInstance();
  int? _subscribedUserId;
  bool _isInitializingPusher = false;

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

  bool isLoadingChat(int partnerId) => _loadingChatPartners.contains(partnerId);

  Future<void> initPusher(int currentUserId) async {
    if (currentUserId <= 0 ||
        _subscribedUserId == currentUserId ||
        _isInitializingPusher) {
      return;
    }
    _isInitializingPusher = true;
    try {
      if (_subscribedUserId != null) {
        await _pusher.unsubscribe(channelName: 'chat-user-$_subscribedUserId');
      }
      await _pusher.init(
        apiKey: ApiConstants.pusherApiKey,
        cluster: ApiConstants.pusherCluster,
        onEvent: (PusherEvent event) {
          if (event.data == null) return;
          final Map<String, dynamic> decoded = event.data is String
              ? jsonDecode(event.data)
              : Map<String, dynamic>.from(event.data);

          if (event.eventName == 'new-message') {
            final incomingMsg = DirectMessageModel.fromJson(decoded);
            final partnerId = incomingMsg.senderId;
            final currentList = List<DirectMessageModel>.from(
              _messagesByPartner[partnerId] ?? const [],
            );
            if (!currentList.any((m) => m.id == incomingMsg.id)) {
              currentList.add(incomingMsg);
              _messagesByPartner[partnerId] = currentList;
            }
            fetchConversations(currentUserId, silent: true);
            notifyListeners();
          } else if (event.eventName == 'message-updated') {
            final msgId = int.tryParse(decoded['id']?.toString() ?? '0') ?? 0;
            final partnerId =
                int.tryParse(decoded['sender_id']?.toString() ?? '0') ?? 0;
            final newText = decoded['text']?.toString() ?? '';
            if (msgId > 0 && partnerId > 0) {
              _applyMessageEditLocal(partnerId, msgId, newText);
              fetchConversations(currentUserId, silent: true);
            }
          } else if (event.eventName == 'message-deleted') {
            final msgId = int.tryParse(decoded['id']?.toString() ?? '0') ?? 0;
            final partnerId =
                int.tryParse(decoded['sender_id']?.toString() ?? '0') ?? 0;
            if (msgId > 0 && partnerId > 0) {
              _applyMessageDeleteLocal(partnerId, msgId);
              fetchConversations(currentUserId, silent: true);
            }
          }
        },
      );
      await _pusher.subscribe(channelName: 'chat-user-$currentUserId');
      await _pusher.connect();
      _subscribedUserId = currentUserId;
    } catch (e) {
      debugPrint('Pusher error: $e');
    } finally {
      _isInitializingPusher = false;
    }
  }

  void _applyMessageEditLocal(int partnerId, int messageId, String newText) {
    final currentList = List<DirectMessageModel>.from(
      _messagesByPartner[partnerId] ?? const [],
    );
    bool changed = false;
    for (int i = 0; i < currentList.length; i++) {
      final m = currentList[i];
      if (m.id == messageId) {
        currentList[i] = m.copyWith(text: newText, isEdited: true);
        changed = true;
      } else if (m.replyToId == messageId) {
        currentList[i] = m.copyWith(replyToText: newText);
        changed = true;
      }
    }
    if (changed) {
      _messagesByPartner[partnerId] = currentList;
      notifyListeners();
    }
  }

  void _applyMessageDeleteLocal(int partnerId, int messageId) {
    final currentList = List<DirectMessageModel>.from(
      _messagesByPartner[partnerId] ?? const [],
    );
    final beforeLen = currentList.length;
    currentList.removeWhere((m) => m.id == messageId);

    for (int i = 0; i < currentList.length; i++) {
      final m = currentList[i];
      if (m.replyToId == messageId) {
        currentList[i] = m.copyWith(replyToText: 'Pesan telah dihapus');
      }
    }

    if (currentList.length != beforeLen) {
      _messagesByPartner[partnerId] = currentList;
      notifyListeners();
    }
  }

  Future<void> fetchConversations(int userId, {bool silent = false}) async {
    if (userId <= 0) return;
    initPusher(userId);
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
            .map(
              (e) => ConversationModel.fromJson(Map<String, dynamic>.from(e)),
            )
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
    initPusher(userId);
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
        final serverList = raw
            .whereType<Map>()
            .map(
              (e) => DirectMessageModel.fromJson(Map<String, dynamic>.from(e)),
            )
            .toList();

        // Pertahankan pesan optimistik (id sementara yang belum selesai dikirim)
        final existing = _messagesByPartner[partnerId] ?? const [];
        final pendingOptimistic = existing
            .where((m) => m.id > 1000000000000)
            .toList();

        _messagesByPartner[partnerId] = [...serverList, ...pendingOptimistic];
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
    int? replyToId,
    String? replyToText,
    int? replyToSenderId,
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
      replyToId: replyToId,
      replyToText: replyToText,
      replyToSenderId: replyToSenderId,
      isEdited: false,
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
          if (replyToId != null && replyToId > 0) 'reply_to_id': replyToId,
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
        } else if (!updated.any((m) => m.id == realMsg.id)) {
          updated.add(realMsg);
        }
        _messagesByPartner[receiverId] = updated;
        notifyListeners();
      }

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

  Future<bool> editMessage({
    required int messageId,
    required int senderId,
    required int partnerId,
    required String newText,
  }) async {
    final trimmed = newText.trim();
    if (messageId <= 0 || senderId <= 0 || trimmed.isEmpty) return false;

    final currentList = List<DirectMessageModel>.from(
      _messagesByPartner[partnerId] ?? const [],
    );
    final idx = currentList.indexWhere((m) => m.id == messageId);
    final oldMsg = idx != -1 ? currentList[idx] : null;

    // Optimistic update
    _applyMessageEditLocal(partnerId, messageId, trimmed);

    try {
      await _apiClient.post(
        ApiConstants.updateMessage,
        body: {'message_id': messageId, 'sender_id': senderId, 'text': trimmed},
      );
      fetchConversations(senderId, silent: true);
      return true;
    } catch (_) {
      if (oldMsg != null) {
        _applyMessageEditLocal(partnerId, messageId, oldMsg.text);
      }
      return false;
    }
  }

  Future<bool> deleteMessage({
    required int messageId,
    required int senderId,
    required int partnerId,
  }) async {
    if (messageId <= 0 || senderId <= 0) return false;

    final backupList = List<DirectMessageModel>.from(
      _messagesByPartner[partnerId] ?? const [],
    );

    // Optimistic delete
    _applyMessageDeleteLocal(partnerId, messageId);

    try {
      await _apiClient.post(
        ApiConstants.deleteMessage,
        body: {'message_id': messageId, 'sender_id': senderId},
      );
      fetchConversations(senderId, silent: true);
      return true;
    } catch (_) {
      _messagesByPartner[partnerId] = backupList;
      notifyListeners();
      return false;
    }
  }
}
