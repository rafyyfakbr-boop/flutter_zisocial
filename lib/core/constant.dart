class ApiConstants {
  static String get baseUrl {
    return 'https://iodize-tiny-icky.ngrok-free.dev/ziesocial/api';
  }

  static String get login => '$baseUrl/auth/login.php';
  static String get register => '$baseUrl/auth/register.php';
  static String createPost = '$baseUrl/posts/create.php';
}