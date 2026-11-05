import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zisocial/model/post_model.dart';
import 'package:zisocial/viewmodel/post_viewmodel.dart';
import 'package:zisocial/widget/post_card.dart';

class PostDetailView extends StatelessWidget {
  final PostModel post;

  const PostDetailView({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Postingan',
          style: TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 20,
            color: Color(0xFF111827),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE5E7EB)),
        ),
      ),
      body: Consumer<PostViewModel>(
        builder: (context, postVM, _) {
          // Cari post terbaru dari list VM agar like/comment count sinkron
          final currentPost = postVM.posts.firstWhere(
            (p) => p.id == post.id,
            orElse: () => post,
          );

          // Jika post sudah dihapus dari VM, tampilkan info
          if (!postVM.posts.any((p) => p.id == post.id)) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Postingan ini sudah dihapus.',
                    style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            child: PostCard(key: ValueKey(currentPost.id), post: currentPost),
          );
        },
      ),
    );
  }
}
