import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zisocial/view/create_post_view.dart';
import 'package:zisocial/view/login_view.dart';
import 'package:zisocial/viewmodel/login_viewmodel.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  void _logout(BuildContext context) {
    context.read<LoginViewModel>().logout();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginView(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ZieSocial'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreatePostView(),
                ),
              );
            },
            icon: const Icon(Icons.add),
            tooltip: 'Buat postingan',
          ),

          IconButton(
            onPressed: () {
              _logout(context);
            },
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: const Padding(
        padding: EdgeInsets.all(24),
        child: Text('Selamat datang'),
      ),
    );
  }
}