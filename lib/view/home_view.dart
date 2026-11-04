import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zisocial/core/constant.dart';
import 'package:zisocial/view/create_post_view.dart';
import 'package:zisocial/view/dm_view.dart';
import 'package:zisocial/view/edit_profile_view.dart';
import 'package:zisocial/view/follow_list_view.dart';
import 'package:zisocial/view/login_view.dart';
import 'package:zisocial/view/post_detail_view.dart';
import 'package:zisocial/viewmodel/follow_viewmodel.dart';
import 'package:zisocial/viewmodel/login_viewmodel.dart';
import 'package:zisocial/viewmodel/message_viewmodel.dart';
import 'package:zisocial/viewmodel/post_viewmodel.dart';
import 'package:zisocial/widget/animated_bottom_nav.dart';
import 'package:zisocial/widget/post_card.dart';
import 'package:zisocial/widget/search_users_section.dart';

const Color primaryColor = Color(0xFF4F46E5);
const Color mutedColor = Color(0xFF6B7280);

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int _selectedTab = 0;
  int _profileSubTab = 0;

  int get _currentUserId {
    final user = context.read<LoginViewModel>().user;
    return int.tryParse(user?.id ?? '0') ?? 0;
  }

  final List<StoryItem> _stories = const [
    StoryItem(username: 'sarah.j', color: Color(0xFFDBA77A)),
    StoryItem(username: 'mike_dev', color: Color(0xFF8195A8)),
    StoryItem(username: 'art.flow', color: Color(0xFFD7A4C2)),
    StoryItem(username: 'doggo', color: Color(0xFF8DBB8B)),
    StoryItem(username: 'travel.id', color: Color(0xFFDBB86C)),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid =
          int.tryParse(context.read<LoginViewModel>().user?.id ?? '0') ?? 0;
      context.read<PostViewModel>().fetchPosts(userId: uid);
      if (uid != 0) {
        context.read<FollowViewModel>().fetchStats(uid, uid);
        context.read<MessageViewModel>().fetchConversations(uid, silent: true);
      }
    });
  }

  void _openCreatePost() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CreatePostView(),
      ),
    );

    // Refresh feed postingan setelah kembali dari create post
    if (mounted) {
      context
          .read<PostViewModel>()
          .fetchPosts(isRefresh: true, userId: _currentUserId);
    }
  }

  void _refreshOwnStats() {
    final uid = _currentUserId;
    if (uid != 0) {
      context.read<FollowViewModel>().fetchStats(uid, uid);
    }
  }

  void _openFollowList(int userId, String username, int tab) async {
    if (userId == 0) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FollowListView(
          userId: userId,
          username: username,
          initialTab: tab,
        ),
      ),
    );
    // Angka bisa berubah jika user follow/unfollow dari daftar
    if (mounted) _refreshOwnStats();
  }

  void _openEditProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EditProfileView()),
    );
  }

  void _logout() {
    context.read<LoginViewModel>().logout();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginView(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<LoginViewModel>().user;
    final unreadCount = context.watch<MessageViewModel>().totalUnreadCount;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        title: Row(
          children: [
            GestureDetector(
              onTap: () {
                setState(() => _selectedTab = 1);
                _refreshOwnStats();
              },
              child: _Avatar(
                imageUrl: user?.avatar ?? '',
                fallbackIcon: Icons.person,
                size: 32,
              ),
            ),
            const Spacer(),
            const Text(
              'ZieSocial',
              style: TextStyle(
                color: primaryColor,
                fontSize: 23,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.6,
              ),
            ),
            const Spacer(),
            // Tombol Direct Message (DM) di AppBar dengan badge
            Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  tooltip: 'Pesan Langsung (DM)',
                  onPressed: () {
                    setState(() => _selectedTab = 3);
                    if (_currentUserId != 0) {
                      context
                          .read<MessageViewModel>()
                          .fetchConversations(_currentUserId);
                    }
                  },
                  icon: const Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: Color(0xFF374151),
                    size: 24,
                  ),
                ),
                if (unreadCount > 0)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7C3AED), Color(0xFF06B6D4)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Text(
                        unreadCount > 99 ? '99+' : unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            PopupMenuButton<String>(
              tooltip: 'Menu akun',
              icon: const Icon(
                Icons.more_vert,
                color: Color(0xFF374151),
              ),
              onSelected: (value) {
                if (value == 'create') {
                  _openCreatePost();
                } else if (value == 'edit_profile') {
                  _openEditProfile();
                } else if (value == 'logout') {
                  _logout();
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'create',
                  child: Text('Buat postingan'),
                ),
                PopupMenuItem(
                  value: 'edit_profile',
                  child: Text('Edit profil'),
                ),
                PopupMenuItem(
                  value: 'logout',
                  child: Text('Logout'),
                ),
              ],
            ),
          ],
        ),
      ),
      body: IndexedStack(
        index: _selectedTab,
        children: [
          _buildHomeFeed(user),
          _buildProfile(user),
          _buildSearch(),
          const DmInboxView(showBackButton: false),
        ],
      ),
      floatingActionButton: _selectedTab == 0
          ? FloatingActionButton(
              onPressed: _openCreatePost,
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              tooltip: 'Buat postingan',
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: AnimatedBottomNav(
        currentIndex: _selectedTab,
        onTap: (index) {
          setState(() => _selectedTab = index);
          if (index == 1) _refreshOwnStats();
          if (index == 3 && _currentUserId != 0) {
            context.read<MessageViewModel>().fetchConversations(_currentUserId);
          }
        },
        items: [
          const AnimatedNavItem(
            outlineIcon: Icons.home_outlined,
            filledIcon: Icons.home_rounded,
            label: 'Home',
          ),
          const AnimatedNavItem(
            outlineIcon: Icons.person_outline_rounded,
            filledIcon: Icons.person_rounded,
            label: 'Profile',
          ),
          const AnimatedNavItem(
            outlineIcon: Icons.search_outlined,
            filledIcon: Icons.search_rounded,
            label: 'Search',
          ),
          AnimatedNavItem(
            outlineIcon: Icons.chat_bubble_outline_rounded,
            filledIcon: Icons.chat_bubble_rounded,
            label: 'DM',
            badgeCount: unreadCount,
          ),
        ],
      ),
    );
  }


  Widget _buildHomeFeed(dynamic user) {
    final postViewModel = context.watch<PostViewModel>();

    return RefreshIndicator(
      onRefresh: () => context.read<PostViewModel>().fetchPosts(isRefresh: true, userId: _currentUserId),
      color: primaryColor,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        children: [
          // Stories horizontal
          SizedBox(
            height: 116,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 8,
              ),
              children: [
                _YourStory(
                  name: user?.username?.isNotEmpty == true
                      ? user.username
                      : 'Your Story',
                  imageUrl: user?.avatar ?? '',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Fitur story belum tersedia.'),
                      ),
                    );
                  },
                ),
                ..._stories.map(
                  (story) => _StoryAvatar(story: story),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFF1F1F1)),

          // 1. Loading State
          if (postViewModel.isLoading && postViewModel.posts.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    CircularProgressIndicator(color: primaryColor),
                    SizedBox(height: 16),
                    Text(
                      'Memuat postingan...',
                      style: TextStyle(color: mutedColor, fontSize: 13),
                    ),
                  ],
                ),
              ),
            )
          // 2. Error State
          else if (postViewModel.hasError && postViewModel.posts.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.cloud_off_rounded,
                      size: 54,
                      color: mutedColor,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      postViewModel.errorMessage ?? 'Gagal memuat postingan.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF374151),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () =>
                          context.read<PostViewModel>().fetchPosts(userId: _currentUserId),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            )
          // 3. Empty State
          else if (postViewModel.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.photo_library_outlined,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Belum Ada Postingan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Jadilah yang pertama membagikan foto atau momen Anda!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: mutedColor, fontSize: 13),
                    ),
                    const SizedBox(height: 18),
                    OutlinedButton.icon(
                      onPressed: _openCreatePost,
                      icon: const Icon(Icons.add_photo_alternate_outlined),
                      label: const Text('Buat Postingan'),
                    ),
                  ],
                ),
              ),
            )
          // 4. Feed Postingan dari API
          else
            ...postViewModel.posts.map(
              (post) => PostCard(
                key: ValueKey(post.id),
                post: post,
              ),
            ),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildProfile(dynamic user) {
    final username = user?.username ?? '';
    final name = user?.name ?? '';
    final bio = user?.bio ?? '';
    final avatarUrl = ApiConstants.getImageUrl(user?.avatar);
    final userId = user?.id ?? '';
    final userIdInt = int.tryParse(userId.toString()) ?? 0;

    final postVM = context.watch<PostViewModel>();
    final followVM = context.watch<FollowViewModel>();
    final followStats = followVM.getStats(userIdInt);

    // Filter postingan milik user yang login
    final userPosts = postVM.posts
        .where((p) => p.author?.id.toString() == userId.toString())
        .toList();
    final savedPosts = postVM.posts.where((p) => p.isSaved).toList();
    final likedPosts = postVM.posts.where((p) => p.isLiked).toList();
    final displayedPosts = _profileSubTab == 0
        ? userPosts
        : (_profileSubTab == 1 ? savedPosts : likedPosts);

    return CustomScrollView(
      slivers: [
        // ── App Bar Profil ──────────────────────────────────────
        SliverAppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          floating: true,
          snap: true,
          elevation: 0,
          automaticallyImplyLeading: false,
          titleSpacing: 20,
          title: const Text(
            'ZieSocial',
            style: TextStyle(
              color: primaryColor,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          actions: [
            IconButton(
              tooltip: 'Edit Profil',
              icon: const Icon(Icons.edit_outlined, color: primaryColor),
              onPressed: _openEditProfile,
            ),
            const SizedBox(width: 4),
          ],
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(height: 1, color: Color(0xFFE5E7EB)),
          ),
        ),

        // ── Info Profil ─────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
            child: Column(
              children: [
                // Avatar dengan border gradient
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: avatarUrl.isNotEmpty &&
                            avatarUrl.startsWith('http')
                        ? const LinearGradient(
                            colors: [
                              Color(0xFF4F46E5),
                              Color(0xFFEC4899),
                              Color(0xFFF59E0B),
                            ],
                          )
                        : null,
                    color: avatarUrl.isEmpty ? const Color(0xFFE5E7EB) : null,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: _Avatar(
                      imageUrl: avatarUrl,
                      fallbackIcon: Icons.person,
                      size: 84,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Username bold + nama
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF111827),
                    ),
                    children: [
                      TextSpan(
                        text: username.isNotEmpty ? '@$username' : '',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      if (name.isNotEmpty)
                        TextSpan(
                          text: '  $name',
                          style: const TextStyle(
                            color: Color(0xFF6B7280),
                            fontWeight: FontWeight.w400,
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                ),

                // Bio
                if (bio.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    bio,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF374151),
                      height: 1.5,
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // Stats: Posts, Followers, Following
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ProfileStat(
                      value: _formatCount(userPosts.length),
                      label: 'Posts',
                    ),
                    _statDivider(),
                    _ProfileStat(
                      value: _formatCount(followStats?.followersCount ?? 0),
                      label: 'Followers',
                      onTap: () => _openFollowList(userIdInt, username, 0),
                    ),
                    _statDivider(),
                    _ProfileStat(
                      value: _formatCount(followStats?.followingCount ?? 0),
                      label: 'Following',
                      onTap: () => _openFollowList(userIdInt, username, 1),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Tombol aksi
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _openCreatePost,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primaryColor,
                          side: const BorderSide(color: primaryColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
                        label: const Text(
                          'Post',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton(
                      onPressed: _logout,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF6B7280),
                        side: const BorderSide(color: Color(0xFFD1D5DB)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 16),
                      ),
                      child: const Icon(Icons.logout, size: 18),
                    ),
                  ],
                ),

                const SizedBox(height: 4),
              ],
            ),
          ),
        ),

        // ── Tab Sub-Profil (Postingan / Favorit / Disukai) ──────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Column(
              children: [
                const Divider(height: 1, color: Color(0xFFE5E7EB)),
                Row(
                  children: [
                    _buildProfileTabButton(
                      index: 0,
                      icon: Icons.grid_on_rounded,
                      label: 'Postingan',
                    ),
                    _buildProfileTabButton(
                      index: 1,
                      icon: Icons.bookmark_border_rounded,
                      activeIcon: Icons.bookmark_rounded,
                      label: 'Favorit',
                    ),
                    _buildProfileTabButton(
                      index: 2,
                      icon: Icons.favorite_border_rounded,
                      activeIcon: Icons.favorite_rounded,
                      label: 'Disukai',
                    ),
                  ],
                ),
                const Divider(height: 1, color: Color(0xFFE5E7EB)),
              ],
            ),
          ),
        ),

        // ── Grid Postingan ──────────────────────────────────────
        if (postVM.isLoading && postVM.posts.isEmpty)
          const SliverFillRemaining(
            child: Center(
              child: CircularProgressIndicator(color: primaryColor),
            ),
          )
        else if (displayedPosts.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _profileSubTab == 0
                          ? Icons.photo_library_outlined
                          : (_profileSubTab == 1
                              ? Icons.bookmark_border_rounded
                              : Icons.favorite_border_rounded),
                      size: 56,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _profileSubTab == 0
                          ? 'Belum Ada Postingan'
                          : (_profileSubTab == 1
                              ? 'Belum Ada Favorit'
                              : 'Belum Ada yang Disukai'),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _profileSubTab == 0
                          ? 'Bagikan momen pertamamu!'
                          : (_profileSubTab == 1
                              ? 'Tekan ikon bookmark pada postingan untuk menyimpannya ke favorit.'
                              : 'Postingan yang kamu sukai akan muncul di sini.'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: mutedColor, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.all(2),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final post = displayedPosts[index];
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
                      decoration: const BoxDecoration(
                        color: Color(0xFFF3F4F6),
                      ),
                      child: post.fullImageUrl.isNotEmpty
                          ? Image.network(
                              post.fullImageUrl,
                              headers: const {
                                'ngrok-skip-browser-warning': 'true',
                              },
                              fit: BoxFit.cover,
                              loadingBuilder: (ctx, child, prog) {
                                if (prog == null) return child;
                                return const Center(
                                  child: CircularProgressIndicator(
                                    color: primaryColor,
                                    strokeWidth: 2,
                                  ),
                                );
                              },
                              errorBuilder: (ctx, _, e) => const Center(
                                child: Icon(
                                  Icons.broken_image_outlined,
                                  color: mutedColor,
                                  size: 28,
                                ),
                              ),
                            )
                          : const Center(
                              child: Icon(
                                Icons.image_not_supported_outlined,
                                color: mutedColor,
                                size: 28,
                              ),
                            ),
                    ),
                  );
                },
                childCount: displayedPosts.length,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 0,
                mainAxisSpacing: 0,
                childAspectRatio: 1,
              ),
            ),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }

  Widget _buildProfileTabButton({
    required int index,
    required IconData icon,
    IconData? activeIcon,
    required String label,
  }) {
    final isSelected = _profileSubTab == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _profileSubTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? primaryColor : Colors.transparent,
                width: 2.5,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSelected ? (activeIcon ?? icon) : icon,
                size: 20,
                color: isSelected ? primaryColor : mutedColor,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? primaryColor : mutedColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Format angka: 1400 → 1.4k, 1200000 → 1.2M
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

  Widget _buildSearch() {
    return const SearchUsersSection();
  }
}

// Model story sederhana untuk UI.
class StoryItem {
  final String username;
  final Color color;

  const StoryItem({
    required this.username,
    required this.color,
  });
}


class _Avatar extends StatelessWidget {
  final String imageUrl;
  final IconData fallbackIcon;
  final double size;

  const _Avatar({
    required this.imageUrl,
    required this.fallbackIcon,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedUrl = ApiConstants.getImageUrl(imageUrl);
    final isValid = resolvedUrl.startsWith('http') && !resolvedUrl.contains('url-ke-gambar.com');

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: const Color(0xFFE5E7EB),
      onBackgroundImageError: isValid ? (_, _) {} : null,
      backgroundImage: isValid
          ? NetworkImage(
              resolvedUrl,
              headers: const {'ngrok-skip-browser-warning': 'true'},
            )
          : null,
      child: isValid
          ? null
          : Icon(fallbackIcon, color: mutedColor, size: size * 0.55),
    );
  }
}

class _YourStory extends StatelessWidget {
  final String name;
  final String imageUrl;
  final VoidCallback onTap;

  const _YourStory({
    required this.name,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 76,
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: _Avatar(
                    imageUrl: imageUrl,
                    fallbackIcon: Icons.person,
                    size: 50,
                  ),
                ),
                Positioned(
                  right: -1,
                  bottom: -1,
                  child: Container(
                    decoration: BoxDecoration(
                      color: primaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.add,
                      size: 17,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            const Text(
              'Your Story',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoryAvatar extends StatelessWidget {
  final StoryItem story;

  const _StoryAvatar({required this.story});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 76,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Color(0xFF4F46E5),
                  Color(0xFFEC4899),
                  Color(0xFFF59E0B),
                ],
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: CircleAvatar(
                radius: 25,
                backgroundColor: story.color,
                child: Text(
                  story.username.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 7),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(
              story.username,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


// ── Widget _ProfileStat ────────────────────────────────────────────────────
class _ProfileStat extends StatelessWidget {
  final String value;
  final String label;
  final VoidCallback? onTap;

  const _ProfileStat({required this.value, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
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
            color: Color(0xFF6B7280),
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
}
