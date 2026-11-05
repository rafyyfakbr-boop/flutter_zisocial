import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zisocial/model/follow_model.dart';
import 'package:zisocial/view/dm_view.dart';
import 'package:zisocial/view/user_profile_view.dart';
import 'package:zisocial/viewmodel/follow_viewmodel.dart';
import 'package:zisocial/viewmodel/login_viewmodel.dart';

const Color _primary = Color(0xFF4F46E5);
const Color _muted = Color(0xFF6B7280);

class SearchUsersSection extends StatefulWidget {
  const SearchUsersSection({super.key});

  @override
  State<SearchUsersSection> createState() => _SearchUsersSectionState();
}

class _SearchUsersSectionState extends State<SearchUsersSection> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  List<FollowUserModel> _results = [];
  bool _isLoading = false;
  bool _hasLoadedInitial = false;

  int get _viewerId =>
      int.tryParse(context.read<LoginViewModel>().user?.id ?? '0') ?? 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _performSearch('');
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    setState(() {});
    _debounce = Timer(const Duration(milliseconds: 280), () {
      _performSearch(value);
    });
  }

  Future<void> _performSearch(String query) async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final list = await context.read<FollowViewModel>().searchUsers(
        query,
        _viewerId,
      );
      if (!mounted) return;
      setState(() {
        _results = list;
        _hasLoadedInitial = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _hasLoadedInitial = true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: TextField(
            controller: _searchController,
            onChanged: _onQueryChanged,
            textInputAction: TextInputAction.search,
            onSubmitted: _performSearch,
            decoration: InputDecoration(
              hintText: 'Cari nama atau @username...',
              hintStyle: const TextStyle(color: _muted, fontSize: 14),
              prefixIcon: const Icon(Icons.search_rounded, color: _muted),
              suffixIcon: query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 19,
                        color: _muted,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        _onQueryChanged('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: const Color(0xFFF3F4F6),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
          child: Text(
            query.isEmpty ? 'Disarankan untuk Anda' : 'Hasil Pencarian',
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: _muted,
              letterSpacing: 0.2,
            ),
          ),
        ),
        Expanded(
          child: _isLoading && !_hasLoadedInitial
              ? const Center(child: CircularProgressIndicator(color: _primary))
              : RefreshIndicator(
                  color: _primary,
                  onRefresh: () => _performSearch(_searchController.text),
                  child: _results.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            const SizedBox(height: 90),
                            Icon(
                              Icons.person_search_outlined,
                              size: 58,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              query.isEmpty
                                  ? 'Belum ada pengguna lain'
                                  : 'Akun "$query" tidak ditemukan',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 40),
                              child: Text(
                                'Coba gunakan kata kunci nama atau username yang berbeda.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: _muted, fontSize: 13),
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(top: 4, bottom: 80),
                          itemCount: _results.length,
                          itemBuilder: (context, index) {
                            return _SearchUserTile(user: _results[index]);
                          },
                        ),
                ),
        ),
      ],
    );
  }
}

class _SearchUserTile extends StatelessWidget {
  final FollowUserModel user;

  const _SearchUserTile({required this.user});

  @override
  Widget build(BuildContext context) {
    final viewerId =
        int.tryParse(context.watch<LoginViewModel>().user?.id ?? '0') ?? 0;
    final isMe = user.id == viewerId;
    final avatarUrl = user.fullAvatarUrl;
    final hasAvatar =
        avatarUrl.startsWith('http') &&
        !avatarUrl.contains('url-ke-gambar.com');
    final displayName = user.name.isNotEmpty ? user.name : user.username;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
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
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Tombol Kirim Pesan (DM)
                IconButton(
                  tooltip: 'Kirim Pesan',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DmChatView(
                          partnerId: user.id,
                          partnerUsername: user.username,
                          partnerName: user.name,
                          partnerAvatar: avatarUrl,
                          partnerBio: user.bio,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 20,
                    color: _primary,
                  ),
                ),
                // Tombol Follow / Mengikuti
                Consumer<FollowViewModel>(
                  builder: (context, followVM, _) {
                    final isFollowing =
                        followVM.getStats(user.id)?.isFollowing ?? false;
                    return SizedBox(
                      height: 33,
                      child: isFollowing
                          ? OutlinedButton(
                              onPressed: () =>
                                  followVM.toggleFollow(user.id, viewerId),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF374151),
                                side: const BorderSide(
                                  color: Color(0xFFD1D5DB),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'Mengikuti',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            )
                          : ElevatedButton(
                              onPressed: () =>
                                  followVM.toggleFollow(user.id, viewerId),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 15,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'Ikuti',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                    );
                  },
                ),
              ],
            ),
    );
  }
}
