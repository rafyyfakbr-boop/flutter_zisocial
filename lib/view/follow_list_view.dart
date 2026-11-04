import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zisocial/model/follow_model.dart';
import 'package:zisocial/view/user_profile_view.dart';
import 'package:zisocial/viewmodel/follow_viewmodel.dart';
import 'package:zisocial/viewmodel/login_viewmodel.dart';

const Color _primary = Color(0xFF4F46E5);
const Color _muted = Color(0xFF6B7280);

/// Halaman daftar Followers & Following milik [userId].
class FollowListView extends StatelessWidget {
  final int userId;
  final String username;

  /// 0 = Followers, 1 = Following
  final int initialTab;

  const FollowListView({
    super.key,
    required this.userId,
    required this.username,
    this.initialTab = 0,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: initialTab,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                size: 20, color: Color(0xFF111827)),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            username.isNotEmpty ? '@$username' : 'Koneksi',
            style: const TextStyle(
              color: Color(0xFF111827),
              fontWeight: FontWeight.w700,
              fontSize: 17,
            ),
          ),
          bottom: const TabBar(
            labelColor: Color(0xFF111827),
            unselectedLabelColor: _muted,
            indicatorColor: _primary,
            indicatorWeight: 2.5,
            labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            tabs: [
              Tab(text: 'Followers'),
              Tab(text: 'Following'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _FollowList(userId: userId, type: 'followers'),
            _FollowList(userId: userId, type: 'following'),
          ],
        ),
      ),
    );
  }
}

class _FollowList extends StatefulWidget {
  final int userId;
  final String type;

  const _FollowList({required this.userId, required this.type});

  @override
  State<_FollowList> createState() => _FollowListState();
}

class _FollowListState extends State<_FollowList>
    with AutomaticKeepAliveClientMixin {
  late Future<List<FollowUserModel>> _future;

  int get _viewerId =>
      int.tryParse(context.read<LoginViewModel>().user?.id ?? '0') ?? 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<FollowUserModel>> _load() {
    return context
        .read<FollowViewModel>()
        .fetchFollowList(widget.userId, _viewerId, type: widget.type);
  }

  Future<void> _refresh() async {
    final future = _load();
    setState(() => _future = future);
    await future;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return RefreshIndicator(
      color: _primary,
      onRefresh: _refresh,
      child: FutureBuilder<List<FollowUserModel>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: _primary),
            );
          }

          if (snapshot.hasError) {
            return _message(
              icon: Icons.cloud_off_rounded,
              title: 'Gagal memuat data',
              subtitle: 'Tarik ke bawah untuk mencoba lagi.',
            );
          }

          final users = snapshot.data ?? [];
          if (users.isEmpty) {
            return _message(
              icon: Icons.people_outline,
              title: widget.type == 'followers'
                  ? 'Belum ada followers'
                  : 'Belum mengikuti siapa pun',
              subtitle: widget.type == 'followers'
                  ? 'Orang yang mengikuti akun ini akan muncul di sini.'
                  : 'Akun yang diikuti akan muncul di sini.',
            );
          }

          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: users.length,
            itemBuilder: (context, i) => _UserTile(user: users[i]),
          );
        },
      ),
    );
  }

  Widget _message({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    // ListView agar RefreshIndicator tetap bisa ditarik
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 120),
        Icon(icon, size: 56, color: Colors.grey.shade400),
        const SizedBox(height: 12),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _muted, fontSize: 13),
          ),
        ),
      ],
    );
  }
}

class _UserTile extends StatelessWidget {
  final FollowUserModel user;

  const _UserTile({required this.user});

  @override
  Widget build(BuildContext context) {
    final viewerId =
        int.tryParse(context.watch<LoginViewModel>().user?.id ?? '0') ?? 0;
    final isMe = user.id == viewerId;
    final avatarUrl = user.fullAvatarUrl;
    final hasAvatar = avatarUrl.startsWith('http') &&
        !avatarUrl.contains('url-ke-gambar.com');
    final displayName = user.name.isNotEmpty ? user.name : user.username;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => UserProfileView(
              userId: user.id,
              username: user.username,
              name: user.name,
              avatarUrl: avatarUrl,
              bio: user.bio,
            ),
          ),
        );
      },
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: const Color(0xFFEEF2FF),
        onBackgroundImageError: hasAvatar ? (_, _) {} : null,
        backgroundImage: hasAvatar
            ? NetworkImage(avatarUrl,
                headers: const {'ngrok-skip-browser-warning': 'true'})
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
      title: Text(
        displayName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 14,
          color: Color(0xFF111827),
        ),
      ),
      subtitle: user.username.isNotEmpty
          ? Text(
              '@${user.username}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: _muted),
            )
          : null,
      trailing: isMe || viewerId == 0
          ? null
          : Consumer<FollowViewModel>(
              builder: (context, followVM, _) {
                final isFollowing =
                    followVM.getStats(user.id)?.isFollowing ?? false;
                return SizedBox(
                  height: 34,
                  child: isFollowing
                      ? OutlinedButton(
                          onPressed: () =>
                              followVM.toggleFollow(user.id, viewerId),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF374151),
                            side: const BorderSide(color: Color(0xFFD1D5DB)),
                            padding:
                                const EdgeInsets.symmetric(horizontal: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Mengikuti',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 12)),
                        )
                      : ElevatedButton(
                          onPressed: () =>
                              followVM.toggleFollow(user.id, viewerId),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Ikuti',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 12)),
                        ),
                );
              },
            ),
    );
  }
}

