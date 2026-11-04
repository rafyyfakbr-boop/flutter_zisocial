import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zisocial/model/post_model.dart';
import 'package:zisocial/view/edit_post_view.dart';
import 'package:zisocial/view/user_profile_view.dart';
import 'package:zisocial/viewmodel/follow_viewmodel.dart';
import 'package:zisocial/viewmodel/login_viewmodel.dart';
import 'package:zisocial/viewmodel/post_viewmodel.dart';
import 'package:zisocial/widget/comments_sheet.dart';
import 'package:zisocial/widget/like_animations.dart';

class PostCard extends StatefulWidget {
  final PostModel post;

  const PostCard({
    super.key,
    required this.post,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  static const Color primaryColor = Color(0xFF4F46E5);
  static const Color pinkColor = Color(0xFFF43F5E);
  static const Color mutedColor = Color(0xFF6B7280);

  // Hati besar yang muncul saat double-tap gambar
  final GlobalKey<HeartPopOverlayState> _heartKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    // Ambil status follow author dari server jika belum ada di cache
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final author = widget.post.author;
      final viewerId = _currentUserId;
      if (author == null || author.id == 0 || viewerId == 0) return;
      if (author.id == viewerId) return;
      final followVM = context.read<FollowViewModel>();
      if (followVM.getStats(author.id) == null &&
          !followVM.isLoading(author.id)) {
        followVM.fetchStats(author.id, viewerId);
      }
    });
  }

  int get _currentUserId {
    final user = context.read<LoginViewModel>().user;
    return int.tryParse(user?.id ?? '0') ?? 0;
  }

  void _onDoubleTap() {
    if (!widget.post.isLiked) {
      context.read<PostViewModel>().toggleLike(widget.post.id, _currentUserId);
    }
    _heartKey.currentState?.play();
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Postingan?',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        content:
            const Text('Postingan akan dihapus permanen dan tidak bisa dikembalikan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;
    final success = await context
        .read<PostViewModel>()
        .deletePost(widget.post.id, _currentUserId);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Postingan berhasil dihapus.' : 'Gagal menghapus postingan.',
          ),
        ),
      );
    }
  }

  void _openEdit(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditPostView(post: widget.post),
      ),
    );
  }

  void _openUserProfile(BuildContext context) {
    final author = widget.post.author;
    if (author == null || author.id == 0) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserProfileView(
          userId: author.id,
          username: author.username,
          name: author.name,
          avatarUrl: author.fullAvatarUrl,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final author = post.author;
    final currentUser = context.watch<LoginViewModel>().user;
    final currentUserId = int.tryParse(currentUser?.id ?? '0') ?? 0;
    final isOwner = author?.id == currentUserId && currentUserId != 0;

    final displayName = author?.name.isNotEmpty == true
        ? author!.name
        : (author?.username.isNotEmpty == true ? author!.username : 'Pengguna');
    final username = author?.username ?? '';
    final avatarUrl = author?.fullAvatarUrl ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: const BoxDecoration(color: Colors.white),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                // Avatar
                GestureDetector(
                  onTap: () => _openUserProfile(context),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: primaryColor.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Builder(
                      builder: (context) {
                        final bool hasValidAvatar = avatarUrl.isNotEmpty &&
                            !avatarUrl.contains('url-ke-gambar.com') &&
                            avatarUrl.startsWith('http');
                        return CircleAvatar(
                          radius: 20,
                          backgroundColor: const Color(0xFFEEF2FF),
                          onBackgroundImageError:
                              hasValidAvatar ? (_, _) {} : null,
                          backgroundImage: hasValidAvatar
                              ? NetworkImage(avatarUrl, headers: const {
                                  'ngrok-skip-browser-warning': 'true',
                                })
                              : null,
                          child: !hasValidAvatar
                              ? Text(
                                  displayName.substring(0, 1).toUpperCase(),
                                  style: const TextStyle(
                                    color: primaryColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                )
                              : null,
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Nama & Username
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _openUserProfile(context),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1F2937),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (username.isNotEmpty)
                          Text(
                            '@$username',
                            style: const TextStyle(
                              fontSize: 12,
                              color: mutedColor,
                              fontWeight: FontWeight.w400,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ),
                // Tombol Follow / Mengikuti untuk pengguna lain
                if (!isOwner && currentUserId != 0 && author != null && author.id != 0) ...[
                  const SizedBox(width: 6),
                  Consumer<FollowViewModel>(
                    builder: (context, followVM, _) {
                      final stats = followVM.getStats(author.id);
                      final isFollowing = stats?.isFollowing ?? false;
                      return TextButton.icon(
                        onPressed: () {
                          followVM.toggleFollow(author.id, currentUserId);
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: isFollowing
                                  ? const Color(0xFFD1D5DB)
                                  : primaryColor.withValues(alpha: 0.3),
                            ),
                          ),
                          backgroundColor: isFollowing
                              ? const Color(0xFFF9FAFB)
                              : primaryColor.withValues(alpha: 0.08),
                        ),
                        icon: Icon(
                          isFollowing
                              ? Icons.check
                              : Icons.person_add_alt_1_outlined,
                          size: 13,
                          color: isFollowing ? mutedColor : primaryColor,
                        ),
                        label: Text(
                          isFollowing ? 'Mengikuti' : 'Ikuti',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isFollowing ? mutedColor : primaryColor,
                          ),
                        ),
                      );
                    },
                  ),
                ],
                // Menu opsi (edit/hapus untuk owner, share/lapor untuk user lain)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_horiz, color: Color(0xFF4B5563)),
                  tooltip: 'Opsi',
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (value) {
                    if (value == 'edit') {
                      _openEdit(context);
                    } else if (value == 'delete') {
                      _confirmDelete(context);
                    } else if (value == 'share') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Tautan postingan disalin.')),
                      );
                    } else if (value == 'report') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Laporan Anda telah dikirim.')),
                      );
                    }
                  },
                  itemBuilder: (_) => isOwner
                      ? [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(children: [
                              Icon(Icons.edit_outlined,
                                  size: 18, color: Color(0xFF374151)),
                              SizedBox(width: 10),
                              Text('Edit Postingan'),
                            ]),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(children: [
                              Icon(Icons.delete_outline,
                                  size: 18, color: Colors.red),
                              SizedBox(width: 10),
                              Text('Hapus Postingan',
                                  style: TextStyle(color: Colors.red)),
                            ]),
                          ),
                        ]
                      : [
                          const PopupMenuItem(
                            value: 'share',
                            child: Row(children: [
                              Icon(Icons.share_outlined,
                                  size: 18, color: Color(0xFF374151)),
                              SizedBox(width: 10),
                              Text('Bagikan Postingan'),
                            ]),
                          ),
                          const PopupMenuItem(
                            value: 'report',
                            child: Row(children: [
                              Icon(Icons.flag_outlined,
                                  size: 18, color: Colors.red),
                              SizedBox(width: 10),
                              Text('Laporkan Postingan',
                                  style: TextStyle(color: Colors.red)),
                            ]),
                          ),
                        ],
                ),
              ],
            ),
          ),

          // 2. Gambar Postingan + Animasi Double Tap
          GestureDetector(
            onDoubleTap: _onDoubleTap,
            child: Stack(
              alignment: Alignment.center,
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    color: const Color(0xFFF3F4F6),
                    child: post.fullImageUrl.isNotEmpty
                        ? Image.network(
                            post.fullImageUrl,
                            headers: const {
                              'ngrok-skip-browser-warning': 'true',
                            },
                            width: double.infinity,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: progress.expectedTotalBytes != null
                                      ? progress.cumulativeBytesLoaded /
                                          progress.expectedTotalBytes!
                                      : null,
                                  color: primaryColor,
                                  strokeWidth: 2.5,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(Icons.broken_image_outlined,
                                        size: 48, color: mutedColor),
                                    SizedBox(height: 8),
                                    Text('Gagal memuat gambar',
                                        style: TextStyle(
                                            color: mutedColor, fontSize: 12)),
                                  ],
                                ),
                              );
                            },
                          )
                        : const Center(
                            child: Icon(Icons.image_not_supported_outlined,
                                size: 48, color: mutedColor),
                          ),
                  ),
                ),
                // Hati besar ala Instagram saat double tap
                HeartPopOverlay(key: _heartKey),
              ],
            ),
          ),

          // 3. Tombol Interaksi
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 2),
            child: Row(
              children: [
                // Tombol Like
                IconButton(
                  tooltip: 'Suka',
                  onPressed: () {
                    context
                        .read<PostViewModel>()
                        .toggleLike(post.id, currentUserId);
                  },
                  icon: AnimatedLikeIcon(
                    isLiked: post.isLiked,
                    likedColor: pinkColor,
                  ),
                ),
                // Tombol Komentar
                IconButton(
                  tooltip: 'Komentar',
                  onPressed: () => CommentsSheet.show(context, post),
                  icon: const Icon(Icons.chat_bubble_outline_rounded,
                      color: Color(0xFF374151), size: 24),
                ),
                // Tombol Share
                IconButton(
                  tooltip: 'Bagikan',
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Tautan postingan berhasil disalin.')),
                    );
                  },
                  icon: const Icon(Icons.send_rounded,
                      color: Color(0xFF374151), size: 24),
                ),
                const Spacer(),
                // Tombol Bookmark
                IconButton(
                  tooltip: 'Simpan',
                  onPressed: () {
                    final willBeSaved = !post.isSaved;
                    context.read<PostViewModel>().toggleSave(post.id, currentUserId);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          willBeSaved
                              ? 'Postingan disimpan ke favorit.'
                              : 'Postingan dihapus dari favorit.',
                        ),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  icon: Icon(
                    post.isSaved
                        ? Icons.bookmark
                        : Icons.bookmark_border_rounded,
                    color: post.isSaved ? primaryColor : const Color(0xFF374151),
                    size: 26,
                  ),
                ),
              ],
            ),
          ),

          // 4. Detail: Likes, Caption, Comments, Time
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => CommentsSheet.show(context, post),
                  child: Text(
                    '${post.likeCount} suka • ${post.commentCount} komentar',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                if (post.caption.isNotEmpty)
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFF1F2937), height: 1.4),
                      children: [
                        TextSpan(
                          text:
                              '${author?.name.isNotEmpty == true ? author!.name : displayName} ',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111827),
                          ),
                        ),
                        TextSpan(text: post.caption),
                      ],
                    ),
                  ),
                GestureDetector(
                  onTap: () => CommentsSheet.show(context, post),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      post.commentCount > 0
                          ? 'Lihat semua ${post.commentCount} komentar'
                          : 'Tambahkan komentar...',
                      style: const TextStyle(
                          fontSize: 12,
                          color: mutedColor,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                if (post.formattedTime.isNotEmpty)
                  Text(
                    post.formattedTime,
                    style: const TextStyle(
                      color: mutedColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 10),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF3F4F6)),
        ],
      ),
    );
  }
}
