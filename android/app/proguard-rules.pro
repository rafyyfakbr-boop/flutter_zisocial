# Keep Pusher & Gson classes agar tidak dihapus R8 saat build APK release
-keep class com.pusher.client.** { *; }
-keep class com.google.gson.** { *; }
-dontwarn com.pusher.client.**

