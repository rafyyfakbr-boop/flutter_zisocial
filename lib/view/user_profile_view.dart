import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zisocial/core/constant.dart';
import 'package:zisocial/view/dm_view.dart';
import 'package:zisocial/view/follow_list_view.dart';
import 'package:zisocial/view/post_detail_view.dart';
import 'package:zisocial/viewmodel/follow_viewmodel.dart';
import 'package:zisocial/viewmodel/login_viewmodel.dart';
import 'package:zisocial/viewmodel/post_viewmodel.dart';

const Color _primary = Color(0xFF4F46E5);
const Color _muted = Color(0xFF6B7280);

class UserProfileView extends StatefulWidget {
  final int userId;
  final String username;
  final String name;
  final String avatarUrl;
  final String bio;

  const UserProfileView({
    super.key,
    required this.userId,
    required this.username,
    required this.name,
    this.avatarUrl = '',
    this.bio = '',
  });

  @override
  State<UserProfileView> createState() => _UserProfileViewState();
}

class _UserProfileViewState extends State<UserProfileView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentUser = context.read<LoginViewModel>().user;
      final currentUserId = int.tryParse(currentUser?.id ?? '0') ?? 0;
      context.read<FollowViewModel>().fetchStats(widget.userId, currentUserId);
    });
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return count.toString();
  }

  Widget _statDivider() {
    return Container(
      height: 28,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      color: const Color(0xFFE5E7EB),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<LoginViewModel>().user;
    final currentUserId = int.tryParse(currentUser?.id ?? '0') ?? 0;
    final isMe = widget.userId == currentUserId && currentUserId != 0;

    final postVM = context.watch<PostViewModel>();
    final followVM = context.watch<FollowViewModel>();
    final stats = followVM.getStats(widget.userId);
    final isFollowing = stats?.isFollowing ?? false;

    // Filter postingan milik user ini
    final userPosts = postVM.posts
        .where((p) => p.author?.id == widget.userId)
        .toList();

    final resolvedAvatarUrl = ApiConstants.getImageUrl(widget.avatarUrl);
    final hasValidAvatar =
        resolvedAvatarUrl.isNotEmpty &&
        !resolvedAvatarUrl.contains('url-ke-gambar.com') &&
        resolvedAvatarUrl.startsWith('http');

    return Scaffold(
      backgroundColor: Colors.white,
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
        title: Text(
          widget.username.isNotEmpty ? '@${widget.username}' : widget.name,
          style: const TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
        centerTitle: true,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE5E7EB)),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          // ── Header Profil ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Column(
                children: [
                  // Avatar dengan gradient ring
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: hasValidAvatar
                          ? const LinearGradient(
                              colors: [
                                Color(0xFF4F46E5),
                                Color(0xFFEC4899),
                                Color(0xFFF59E0B),
                              ],
                            )
                          : null,
                      color: !hasValidAvatar ? const Color(0xFFE5E7EB) : null,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: CircleAvatar(
                        radius: 42,
                        backgroundColor: const Color(0xFFEEF2FF),
                        onBackgroundImageError: hasValidAvatar
                            ? (_, _) {}
                            : null,
                        backgroundImage: hasValidAvatar
                            ? NetworkImage(
                                resolvedAvatarUrl,
                                headers: const {
                                  'ngrok-skip-browser-warning': 'true',
                                },
                              )
                            : null,
                        child: !hasValidAvatar
                            ? Text(
                                (widget.name.isNotEmpty
                                        ? widget.name[0]
                                        : (widget.username.isNotEmpty
                                              ? widget.username[0]
                                              : 'U'))
                                    .toUpperCase(),
                                style: const TextStyle(
                                  color: _primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 28,
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Nama User & Username
                  Text(
                    widget.name.isNotEmpty ? widget.name : widget.username,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111827),
                    ),
                  ),
                  if (widget.username.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      '@${widget.username}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: _muted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],

                  // Bio
                  if (widget.bio.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      widget.bio,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF374151),
                        height: 1.4,
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Statistik: Posts, Followers, Following
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildStatItem(
                        value: _formatCount(userPosts.length),
                        label: 'Posts',
                      ),
                      _statDivider(),
                      _buildStatItem(
                        value: _formatCount(stats?.followersCount ?? 0),
                        label: 'Followers',
                        onTap: () => _openFollowList(0),
                      ),
                      _statDivider(),
                      _buildStatItem(
                        value: _formatCount(stats?.followingCount ?? 0),
                        label: 'Following',
                        onTap: () => _openFollowList(1),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Tombol Follow / Unfollow + Kirim Pesan (atau label jika akun sendiri)
                  if (!isMe)
                    Row(
                      children: [
                        Expanded(
                          child: isFollowing
                              ? OutlinedButton.icon(
                                  onPressed: () {
                                    followVM.toggleFollow(
                                      widget.userId,
                                      currentUserId,
                                    );
                                  },
                                  icon: const Icon(Icons.check, size: 18),
                                  label: const Text(
                                    'Mengikuti',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF374151),
                                    side: const BorderSide(
                                      color: Color(0xFFD1D5DB),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                  ),
                                )
                              : ElevatedButton.icon(
                                  onPressed: () {
                                    followVM.toggleFollow(
                                      widget.userId,
                                      currentUserId,
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.person_add_alt_1_outlined,
                                    size: 18,
                                  ),
                                  label: const Text(
                                    'Ikuti',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _primary,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DmChatView(
                                    partnerId: widget.userId,
                                    partnerUsername: widget.username,
                                    partnerName: widget.name,
                                    partnerAvatar: resolvedAvatarUrl,
                                    partnerBio: widget.bio,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 18,
                            ),
                            label: const Text(
                              'Pesan',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _primary,
                              side: const BorderSide(color: _primary),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Ini adalah profil akun Anda',
                        style: TextStyle(
                          color: _muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ── Divider ─────────────────────────────────────────────
          const SliverToBoxAdapter(
            child: Divider(height: 1, color: Color(0xFFE5E7EB)),
          ),

          // ── Grid Postingan User ──────────────────────────────────
          if (userPosts.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.photo_library_outlined,
                      size: 56,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Belum Ada Postingan',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Pengguna ini belum membagikan postingan.',
                      style: TextStyle(color: _muted, fontSize: 13),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(2),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final post = userPosts[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PostDetailView(post: post),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.all(1.5),
                      decoration: const BoxDecoration(color: Color(0xFFF3F4F6)),
                      child: post.fullImageUrl.isNotEmpty
                          ? Image.network(
                              post.fullImageUrl,
                              headers: const {
                                'ngrok-skip-browser-warning': 'true',
                              },
                              fit: BoxFit.cover,
                              errorBuilder: (ctx, _, e) => const Center(
                                child: Icon(
                                  Icons.broken_image_outlined,
                                  color: _muted,
                                  size: 28,
                                ),
                              ),
                            )
                          : const Center(
                              child: Icon(
                                Icons.image_not_supported_outlined,
                                color: _muted,
                                size: 28,
                              ),
                            ),
                    ),
                  );
                }, childCount: userPosts.length),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 0,
                  mainAxisSpacing: 0,
                  childAspectRatio: 1,
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String value,
    required String label,
    VoidCallback? onTap,
  }) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF111827),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: _muted,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );

    if (onTap == null) return content;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: content,
      ),
    );
  }

  void _openFollowList(int tab) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FollowListView(
          userId: widget.userId,
          username: widget.username,
          initialTab: tab,
        ),
      ),
    );
  }
}
