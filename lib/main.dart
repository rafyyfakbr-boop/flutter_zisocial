import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:zisocial/core/network.dart';
import 'package:zisocial/view/login_view.dart';
import 'package:zisocial/viewmodel/comment_viewmodel.dart';
import 'package:zisocial/viewmodel/create_post_viewmodel.dart';
import 'package:zisocial/viewmodel/follow_viewmodel.dart';
import 'package:zisocial/viewmodel/login_viewmodel.dart';
import 'package:zisocial/viewmodel/message_viewmodel.dart';
import 'package:zisocial/viewmodel/post_viewmodel.dart';
import 'package:zisocial/viewmodel/register_viewmodel.dart';

void main() {
  final apiClient = ApiClient();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LoginViewModel(apiClient)),
        ChangeNotifierProvider(create: (_) => RegisterViewModel(apiClient)),
        ChangeNotifierProvider(create: (_) => CreatePostViewModel(apiClient)),
        ChangeNotifierProvider(create: (_) => PostViewModel(apiClient)),
        ChangeNotifierProvider(create: (_) => CommentViewModel(apiClient)),
        ChangeNotifierProvider(create: (_) => FollowViewModel(apiClient)),
        ChangeNotifierProvider(create: (_) => MessageViewModel(apiClient)),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ZieSocial',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4F46E5)),
        useMaterial3: true,
      ),
      home: const LoginView(),
    );
  }
}
