import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zisocial/core/constant.dart';
import 'package:zisocial/model/message_model.dart';
import 'package:zisocial/view/user_profile_view.dart';
import 'package:zisocial/viewmodel/login_viewmodel.dart';
import 'package:zisocial/viewmodel/message_viewmodel.dart';

const Color _primary = Color(0xFF4F46E5);
const Color _violet = Color(0xFF7C3AED);
const Color _cyan = Color(0xFF06B6D4);
const Color _muted = Color(0xFF6B7280);

/// Halaman daftar pesan (Inbox DM) — bisa dipakai sebagai halaman penuh maupun tab.
class DmInboxView extends StatefulWidget {
  final bool showBackButton;

  const DmInboxView({super.key, this.showBackButton = true});

  @override
  State<DmInboxView> createState() => _DmInboxViewState();
}

class _DmInboxViewState extends State<DmInboxView> {
  Timer? _pollTimer;

  int get _currentUserId =>
      int.tryParse(context.read<LoginViewModel>().user?.id ?? '0') ?? 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load();
      _pollTimer = Timer.periodic(const Duration(seconds: 12), (_) {
        if (mounted && _currentUserId > 0) {
          context.read<MessageViewModel>().fetchConversations(
            _currentUserId,
            silent: true,
          );
        }
      });
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final uid = _currentUserId;
    if (uid > 0) {
      await context.read<MessageViewModel>().fetchConversations(uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final msgVM = context.watch<MessageViewModel>();
    final currentUserId =
        int.tryParse(context.watch<LoginViewModel>().user?.id ?? '0') ?? 0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: widget.showBackButton
            ? IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  size: 20,
                  color: Color(0xFF111827),
                ),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        titleSpacing: widget.showBackButton ? 0 : 20,
        title: const Text(
          'Pesan Langsung',
          style: TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.w800,
            fontSize: 19,
            letterSpacing: -0.3,
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE5E7EB)),
        ),
      ),
      body: RefreshIndicator(
        color: _primary,
        onRefresh: _load,
        child: msgVM.isLoadingConversations && msgVM.conversations.isEmpty
            ? const Center(child: CircularProgressIndicator(color: _primary))
            : msgVM.conversations.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 130),
                  Icon(
                    Icons.forum_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Belum Ada Percakapan',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'Cari akun pengguna di tab Search atau buka profil mereka untuk mulai mengirim pesan.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: _muted, fontSize: 13),
                    ),
                  ),
                ],
              )
            : ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: msgVM.conversations.length,
                separatorBuilder: (_, _) => const Divider(
                  height: 1,
                  indent: 78,
                  color: Color(0xFFF3F4F6),
                ),
                itemBuilder: (context, index) {
                  final conv = msgVM.conversations[index];
                  return _ConversationTile(
                    conversation: conv,
                    currentUserId: currentUserId,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DmChatView(
                            partnerId: conv.partnerId,
                            partnerUsername: conv.partnerUsername,
                            partnerName: conv.partnerName,
                            partnerAvatar: conv.fullAvatarUrl,
                            partnerBio: conv.partnerBio,
                          ),
                        ),
                      );
                      if (mounted) _load();
                    },
                  );
                },
              ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final ConversationModel conversation;
  final int currentUserId;
  final VoidCallback onTap;

  const _ConversationTile({
    required this.conversation,
    required this.currentUserId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final avatarUrl = conversation.fullAvatarUrl;
    final hasAvatar =
        avatarUrl.startsWith('http') &&
        !avatarUrl.contains('url-ke-gambar.com');
    final displayName = conversation.partnerName.isNotEmpty
        ? conversation.partnerName
        : conversation.partnerUsername;
    final isUnread = conversation.unreadCount > 0;
    final prefix = conversation.lastSenderId == currentUserId ? 'Anda: ' : '';

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        radius: 26,
        backgroundColor: const Color(0xFFEEF2FF),
        onBackgroundImageError: hasAvatar ? (_, _) {} : null,
        backgroundImage: hasAvatar
            ? NetworkImage(
                avatarUrl,
                headers: const {'ngrok-skip-browser-warning': 'true'},
              )
            : null,
        child: hasAvatar
            ? null
            : Text(
                displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                style: const TextStyle(
                  color: _primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: isUnread ? FontWeight.w800 : FontWeight.w700,
                fontSize: 14.5,
                color: const Color(0xFF111827),
              ),
            ),
          ),
          if (conversation.formattedTime.isNotEmpty)
            Text(
              conversation.formattedTime,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isUnread ? FontWeight.w700 : FontWeight.w400,
                color: isUnread ? _primary : _muted,
              ),
            ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '$prefix${conversation.lastMessage}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isUnread ? FontWeight.w700 : FontWeight.w400,
                  color: isUnread ? const Color(0xFF111827) : _muted,
                ),
              ),
            ),
            if (isUnread)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_violet, _cyan]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  conversation.unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Ruang obrolan 1-on-1 (Direct Message) dengan [partnerId].
class DmChatView extends StatefulWidget {
  final int partnerId;
  final String partnerUsername;
  final String partnerName;
  final String partnerAvatar;
  final String partnerBio;

  const DmChatView({
    super.key,
    required this.partnerId,
    required this.partnerUsername,
    required this.partnerName,
    this.partnerAvatar = '',
    this.partnerBio = '',
  });

  @override
  State<DmChatView> createState() => _DmChatViewState();
}

class _DmChatViewState extends State<DmChatView> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  Timer? _pollTimer;
  int _lastCount = 0;

  DirectMessageModel? _replyingMessage;
  DirectMessageModel? _editingMessage;

  int get _currentUserId =>
      int.tryParse(context.read<LoginViewModel>().user?.id ?? '0') ?? 0;

  String get _partnerDisplayName => widget.partnerName.isNotEmpty
      ? widget.partnerName
      : widget.partnerUsername;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = _currentUserId;
      if (uid > 0) {
        context
            .read<MessageViewModel>()
            .fetchMessages(uid, widget.partnerId)
            .then((_) => _scrollToBottom(jump: true));
      }

      // Backup polling ringan (karena realtime utama sudah ditangani Pusher)
      _pollTimer = Timer.periodic(const Duration(seconds: 15), (_) {
        if (mounted && _currentUserId > 0) {
          context.read<MessageViewModel>().fetchMessages(
            _currentUserId,
            widget.partnerId,
            silent: true,
          );
        }
      });
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _textController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom({bool jump = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final target = _scrollController.position.maxScrollExtent;
      if (jump) {
        _scrollController.jumpTo(target);
      } else {
        _scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _startReply(DirectMessageModel msg) {
    setState(() {
      _editingMessage = null;
      _replyingMessage = msg;
    });
    _focusNode.requestFocus();
  }

  void _startEdit(DirectMessageModel msg) {
    setState(() {
      _replyingMessage = null;
      _editingMessage = msg;
      _textController.text = msg.text;
      _textController.selection = TextSelection.fromPosition(
        TextPosition(offset: _textController.text.length),
      );
    });
    _focusNode.requestFocus();
  }

  void _cancelReplyOrEdit() {
    setState(() {
      if (_editingMessage != null) {
        _textController.clear();
      }
      _replyingMessage = null;
      _editingMessage = null;
    });
  }

  Future<void> _confirmDelete(DirectMessageModel msg) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Hapus Pesan?',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        content: const Text(
          'Pesan ini akan dihapus secara permanen dari obrolan.',
          style: TextStyle(fontSize: 14, color: Color(0xFF4B5563)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: _muted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      if (_editingMessage?.id == msg.id) _cancelReplyOrEdit();
      if (_replyingMessage?.id == msg.id) _cancelReplyOrEdit();

      final ok = await context.read<MessageViewModel>().deleteMessage(
        messageId: msg.id,
        senderId: _currentUserId,
        partnerId: widget.partnerId,
      );
      if (!ok && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Gagal menghapus pesan.')));
      }
    }
  }

  void _showMessageOptions(DirectMessageModel msg, bool isMe) {
    // Abaikan jika pesan masih berstatus optimistic (belum dapat ID server)
    final isSynced = msg.id < 1000000000000;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 38,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 6,
                  ),
                  child: Text(
                    msg.text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: _muted,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                const Divider(height: 12),
                ListTile(
                  leading: const Icon(Icons.reply_rounded, color: _primary),
                  title: const Text(
                    'Balas Pesan (Reply)',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _startReply(msg);
                  },
                ),
                if (isMe && isSynced) ...[
                  ListTile(
                    leading: const Icon(
                      Icons.edit_outlined,
                      color: Color(0xFF0284C7),
                    ),
                    title: const Text(
                      'Edit Pesan',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      _startEdit(msg);
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.delete_outline_rounded,
                      color: Color(0xFFEF4444),
                    ),
                    title: const Text(
                      'Hapus Pesan',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      _confirmDelete(msg);
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleSend() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _currentUserId == 0) return;

    final editing = _editingMessage;
    final replying = _replyingMessage;

    _textController.clear();
    setState(() {
      _editingMessage = null;
      _replyingMessage = null;
    });

    if (editing != null) {
      if (text == editing.text) return;
      final ok = await context.read<MessageViewModel>().editMessage(
        messageId: editing.id,
        senderId: _currentUserId,
        partnerId: widget.partnerId,
        newText: text,
      );
      if (!ok && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Gagal mengedit pesan.')));
      }
      return;
    }

    await context.read<MessageViewModel>().sendMessage(
      senderId: _currentUserId,
      receiverId: widget.partnerId,
      text: text,
      replyToId: replying?.id,
      replyToText: replying?.text,
      replyToSenderId: replying?.senderId,
      partnerUsername: widget.partnerUsername,
      partnerName: widget.partnerName,
      partnerAvatar: widget.partnerAvatar,
      partnerBio: widget.partnerBio,
    );
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final msgVM = context.watch<MessageViewModel>();
    final messages = msgVM.getMessages(widget.partnerId);
    final isLoading = msgVM.isLoadingChat(widget.partnerId) && messages.isEmpty;

    if (messages.length != _lastCount) {
      _lastCount = messages.length;
      _scrollToBottom();
    }

    final resolvedAvatar = ApiConstants.getImageUrl(widget.partnerAvatar);
    final hasAvatar =
        resolvedAvatar.startsWith('http') &&
        !resolvedAvatar.contains('url-ke-gambar.com');
    final displayName = _partnerDisplayName;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 20,
            color: Color(0xFF111827),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => UserProfileView(
                  userId: widget.partnerId,
                  username: widget.partnerUsername,
                  name: widget.partnerName,
                  avatarUrl: resolvedAvatar,
                  bio: widget.partnerBio,
                ),
              ),
            );
          },
          child: Row(
            children: [
              CircleAvatar(
                radius: 19,
                backgroundColor: const Color(0xFFEEF2FF),
                onBackgroundImageError: hasAvatar ? (_, _) {} : null,
                backgroundImage: hasAvatar
                    ? NetworkImage(
                        resolvedAvatar,
                        headers: const {'ngrok-skip-browser-warning': 'true'},
                      )
                    : null,
                child: hasAvatar
                    ? null
                    : Text(
                        displayName.isNotEmpty
                            ? displayName[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          color: _primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                    if (widget.partnerUsername.isNotEmpty)
                      Text(
                        '@${widget.partnerUsername}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11.5, color: _muted),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE5E7EB)),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: _primary),
                  )
                : messages.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 36),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 34,
                            backgroundColor: const Color(0xFFEEF2FF),
                            backgroundImage: hasAvatar
                                ? NetworkImage(
                                    resolvedAvatar,
                                    headers: const {
                                      'ngrok-skip-browser-warning': 'true',
                                    },
                                  )
                                : null,
                            child: hasAvatar
                                ? null
                                : const Icon(
                                    Icons.waving_hand_outlined,
                                    size: 30,
                                    color: _primary,
                                  ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Sapa $displayName!',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Kirim pesan pertamamu untuk memulai obrolan.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: _muted, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final isMe = msg.senderId == _currentUserId;
                      return _MessageBubble(
                        message: msg,
                        isMe: isMe,
                        currentUserId: _currentUserId,
                        partnerName: displayName,
                        onReply: () => _startReply(msg),
                        onLongPress: () => _showMessageOptions(msg, isMe),
                      );
                    },
                  ),
          ),

          // ── Banner Reply / Edit di atas Input Bar ───────────────────
          if (_replyingMessage != null || _editingMessage != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: const BoxDecoration(
                color: Color(0xFFF3F4F6),
                border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
              ),
              child: Row(
                children: [
                  Container(
                    width: 3.5,
                    height: 34,
                    decoration: BoxDecoration(
                      color: _editingMessage != null
                          ? const Color(0xFF0284C7)
                          : _primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(
                    _editingMessage != null
                        ? Icons.edit_outlined
                        : Icons.reply_rounded,
                    size: 18,
                    color: _editingMessage != null
                        ? const Color(0xFF0284C7)
                        : _primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _editingMessage != null
                              ? 'Mengedit pesan'
                              : (_replyingMessage!.senderId == _currentUserId
                                    ? 'Membalas Anda'
                                    : 'Membalas $displayName'),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _editingMessage != null
                                ? const Color(0xFF0284C7)
                                : _primary,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          (_editingMessage ?? _replyingMessage)!.text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF4B5563),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 19,
                      color: _muted,
                    ),
                    onPressed: _cancelReplyOrEdit,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),

          // ── Input Bar Pesan ────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      focusNode: _focusNode,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _handleSend(),
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: _editingMessage != null
                            ? 'Ubah isi pesan...'
                            : (_replyingMessage != null
                                  ? 'Tulis balasan...'
                                  : 'Tulis pesan...'),
                        hintStyle: const TextStyle(color: _muted, fontSize: 14),
                        filled: true,
                        fillColor: const Color(0xFFF3F4F6),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _handleSend,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [_violet, _cyan],
                        ),
                      ),
                      child: Icon(
                        _editingMessage != null
                            ? Icons.check_rounded
                            : Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final DirectMessageModel message;
  final bool isMe;
  final int currentUserId;
  final String partnerName;
  final VoidCallback onReply;
  final VoidCallback onLongPress;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.currentUserId,
    required this.partnerName,
    required this.onReply,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final hasReply =
        message.replyToId != null && (message.replyToText?.isNotEmpty ?? false);
    final replySenderLabel = message.replyToSenderId == currentUserId
        ? 'Anda'
        : partnerName;

    return Dismissible(
      key: ValueKey('msg_swipe_${message.id}'),
      direction: DismissDirection.startToEnd,
      confirmDismiss: (_) async {
        onReply();
        return false; // Jangan hilangkan bubble, cukup trigger reply
      },
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 16),
        child: const CircleAvatar(
          radius: 16,
          backgroundColor: Color(0xFFEEF2FF),
          child: Icon(Icons.reply_rounded, size: 18, color: _primary),
        ),
      ),
      child: GestureDetector(
        onLongPress: onLongPress,
        child: Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.76,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: isMe
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [_violet, _primary, _cyan],
                    )
                  : null,
              color: isMe ? null : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isMe ? 18 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 18),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                // Kotak kutipan Reply jika pesan ini membalas pesan lain
                if (hasReply)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isMe
                          ? Colors.black.withValues(alpha: 0.18)
                          : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(10),
                      border: Border(
                        left: BorderSide(
                          color: isMe ? Colors.white : _primary,
                          width: 3,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          replySenderLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isMe ? Colors.white : _primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          message.replyToText ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: isMe
                                ? Colors.white.withValues(alpha: 0.9)
                                : const Color(0xFF4B5563),
                          ),
                        ),
                      ],
                    ),
                  ),

                Text(
                  message.text,
                  style: TextStyle(
                    color: isMe ? Colors.white : const Color(0xFF111827),
                    fontSize: 14,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (message.isEdited) ...[
                      Text(
                        'diedit • ',
                        style: TextStyle(
                          color: isMe
                              ? Colors.white.withValues(alpha: 0.75)
                              : _muted,
                          fontSize: 10,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                    if (message.formattedHour.isNotEmpty)
                      Text(
                        message.formattedHour,
                        style: TextStyle(
                          color: isMe
                              ? Colors.white.withValues(alpha: 0.78)
                              : _muted,
                          fontSize: 10,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
