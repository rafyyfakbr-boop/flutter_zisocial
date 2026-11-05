class ApiConstants {
  static String baseUrl =
      'https://iodize-tiny-icky.ngrok-free.dev/ziesocial/api';

  static String get login => '$baseUrl/auth/login.php';
  static String get register => '$baseUrl/auth/register.php';
  static String get updateProfile => '$baseUrl/users/update_profile.php';
  static String get searchUsers => '$baseUrl/users/search.php';
  static String get createPost => '$baseUrl/posts/create.php';
  static String get readPosts => '$baseUrl/posts/read.php';
  static String get updatePost => '$baseUrl/posts/update.php';
  static String get deletePost => '$baseUrl/posts/delete.php';
  static String get toggleLike => '$baseUrl/likes/toggle.php';
  static String get toggleSave => '$baseUrl/saves/toggle.php';
  static String get createComment => '$baseUrl/comments/create.php';
  static String get readComments => '$baseUrl/comments/read.php';
  static String get deleteComment => '$baseUrl/comments/delete.php';
  static String get followUser => '$baseUrl/follows/follow.php';
  static String get unfollowUser => '$baseUrl/follows/unfollow.php';
  static String get getFollowStats => '$baseUrl/follows/stats.php';
  static String get getFollowList => '$baseUrl/follows/list.php';
  static String get getConversations => '$baseUrl/messages/conversations.php';
  static String get readMessages => '$baseUrl/messages/read.php';
  static String get sendMessage => '$baseUrl/messages/send.php';
  static String get updateMessage => '$baseUrl/messages/update.php';
  static String get deleteMessage => '$baseUrl/messages/delete.php';

  static String getImageUrl(String? path) {
    if (path == null || path.trim().isEmpty) return '';
    final trimmed = path.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    final hostUrl = baseUrl.endsWith('/api')
        ? baseUrl.substring(0, baseUrl.length - 4)
        : baseUrl;
    final cleanPath = trimmed.startsWith('/') ? trimmed : '/$trimmed';
    return '$hostUrl$cleanPath';
  }

  static const String pusherApiKey = '4bd0794d9d6c703fed0a';
  static const String pusherCluster = 'ap1';
}
