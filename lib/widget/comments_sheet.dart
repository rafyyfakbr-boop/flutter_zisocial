import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zisocial/model/comment_model.dart';
import 'package:zisocial/model/post_model.dart';
import 'package:zisocial/view/user_profile_view.dart';
import 'package:zisocial/viewmodel/comment_viewmodel.dart';
import 'package:zisocial/viewmodel/login_viewmodel.dart';
import 'package:zisocial/viewmodel/post_viewmodel.dart';

class CommentsSheet extends StatefulWidget {
  final PostModel post;

  const CommentsSheet({super.key, required this.post});

  static void show(BuildContext context, PostModel post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CommentsSheet(post: post),
    );
  }

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _canSend = false;

  static const Color pinkColor = Color(0xFFEC4899);
  static const Color mutedColor = Color(0xFF6B7280);

  @override
  void initState() {
    super.initState();
    _commentController.addListener(() {
      final canSend = _commentController.text.trim().isNotEmpty;
      if (canSend != _canSend) {
        setState(() => _canSend = canSend);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CommentViewModel>().fetchComments(widget.post.id);
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final user = context.read<LoginViewModel>().user;
    final userId = int.tryParse(user?.id ?? '1') ?? 1;

    _commentController.clear();
    FocusScope.of(context).unfocus();

    final success = await context.read<CommentViewModel>().addComment(
      postId: widget.post.id,
      userId: userId,
      text: text,
      currentUser: user,
    );

    if (success && mounted) {
      context.read<PostViewModel>().updateCommentCount(widget.post.id, 1);
      // Scroll to bottom
      Future.delayed(const Duration(milliseconds: 200), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  Future<void> _confirmDeleteComment(CommentModel comment) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Hapus Komentar?',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Apakah Anda yakin ingin menghapus komentar ini?',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: mutedColor)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (shouldDelete == true && mounted) {
      await context.read<CommentViewModel>().deleteComment(
        commentId: comment.id,
        postId: widget.post.id,
      );
      if (mounted) {
        context.read<PostViewModel>().updateCommentCount(widget.post.id, -1);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Komentar berhasil dihapus.'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    }
  }

  void _openUserProfile(
    int userId,
    String username,
    String name,
    String avatarUrl,
  ) {
    if (userId == 0) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserProfileView(
          userId: userId,
          username: username,
          name: name,
          avatarUrl: avatarUrl,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final commentViewModel = context.watch<CommentViewModel>();
    final comments = commentViewModel.getComments(widget.post.id);
    final isLoading = commentViewModel.isPostLoading(widget.post.id);
    final currentUser = context.watch<LoginViewModel>().user;
    final currentUserId = int.tryParse(currentUser?.id ?? '0') ?? 0;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.72,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // 1. Handle drag bar
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // 2. Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Spacer(),
                const Text(
                  'Komentar',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 18,
                      color: Color(0xFF4B5563),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),

          // 3. Comments List
          Expanded(
            child: isLoading && comments.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(color: pinkColor),
                  )
                : comments.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFDF2F8),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 40,
                            color: pinkColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Belum ada komentar',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Jadilah yang pertama memulai percakapan!',
                          style: TextStyle(fontSize: 13, color: mutedColor),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final comment = comments[index];
                      final author = comment.author;
                      final displayName = author?.name.isNotEmpty == true
                          ? author!.name
                          : (author?.username.isNotEmpty == true
                                ? author!.username
                                : 'Pengguna');
                      final username = author?.username ?? '';
                      final avatarUrl = author?.fullAvatarUrl ?? '';
                      final hasValidAvatar =
                          avatarUrl.isNotEmpty &&
                          !avatarUrl.contains('url-ke-gambar.com') &&
                          avatarUrl.startsWith('http');

                      // Apakah komentar ini milik user yang sedang login?
                      final isMyComment =
                          (currentUser != null &&
                          (comment.userId == currentUserId ||
                              author?.id == currentUserId ||
                              (username.isNotEmpty &&
                                  username == currentUser.username)));

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Avatar
                            GestureDetector(
                              onTap: () {
                                final uid = author?.id ?? comment.userId;
                                _openUserProfile(
                                  uid,
                                  username,
                                  displayName,
                                  avatarUrl,
                                );
                              },
                              child: CircleAvatar(
                                radius: 17,
                                backgroundColor: const Color(0xFFFCE7F3),
                                onBackgroundImageError: hasValidAvatar
                                    ? (_, _) {}
                                    : null,
                                backgroundImage: hasValidAvatar
                                    ? NetworkImage(
                                        avatarUrl,
                                        headers: const {
                                          'ngrok-skip-browser-warning': 'true',
                                        },
                                      )
                                    : null,
                                child: !hasValidAvatar
                                    ? Text(
                                        displayName.isNotEmpty
                                            ? displayName[0].toUpperCase()
                                            : 'U',
                                        style: const TextStyle(
                                          color: pinkColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Komentar isi
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          final uid =
                                              author?.id ?? comment.userId;
                                          _openUserProfile(
                                            uid,
                                            username,
                                            displayName,
                                            avatarUrl,
                                          );
                                        },
                                        child: Text(
                                          username.isNotEmpty
                                              ? username
                                              : displayName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                            color: Color(0xFF111827),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        comment.formattedTime,
                                        style: const TextStyle(
                                          color: mutedColor,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    comment.text,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF374151),
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Tombol Hapus Komentar (jika milik user sendiri)
                            if (isMyComment)
                              IconButton(
                                tooltip: 'Hapus komentar',
                                iconSize: 18,
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: Colors.redAccent,
                                ),
                                onPressed: () => _confirmDeleteComment(comment),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // 4. Input bar di bagian bawah
          Container(
            padding: EdgeInsets.fromLTRB(16, 10, 16, 12 + bottomInset),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey.shade200, width: 1),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  // Avatar user aktif
                  CircleAvatar(
                    radius: 17,
                    backgroundColor: const Color(0xFFFCE7F3),
                    backgroundImage:
                        (currentUser?.avatar != null &&
                            currentUser!.avatar.startsWith('http') &&
                            !currentUser.avatar.contains('url-ke-gambar.com'))
                        ? NetworkImage(
                            currentUser.avatar,
                            headers: const {
                              'ngrok-skip-browser-warning': 'true',
                            },
                          )
                        : null,
                    child:
                        (currentUser?.avatar == null ||
                            !currentUser!.avatar.startsWith('http') ||
                            currentUser.avatar.contains('url-ke-gambar.com'))
                        ? Text(
                            (currentUser?.name.isNotEmpty == true
                                    ? currentUser!.name[0]
                                    : (currentUser?.username.isNotEmpty == true
                                          ? currentUser!.username[0]
                                          : 'U'))
                                .toUpperCase(),
                            style: const TextStyle(
                              color: pinkColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 10),

                  // Input field
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _commentController,
                        decoration: const InputDecoration(
                          hintText: 'Tambahkan komentar...',
                          hintStyle: TextStyle(color: mutedColor, fontSize: 13),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                        ),
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _submitComment(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Tombol Kirim
                  GestureDetector(
                    onTap: _canSend ? _submitComment : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _canSend ? pinkColor : const Color(0xFFE5E7EB),
                      ),
                      child: commentViewModel.isSubmitting
                          ? const Center(
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          : Icon(
                              Icons.arrow_upward_rounded,
                              size: 20,
                              color: _canSend
                                  ? Colors.white
                                  : const Color(0xFF9CA3AF),
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
