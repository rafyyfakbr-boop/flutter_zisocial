import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:zisocial/viewmodel/login_viewmodel.dart';
import 'package:zisocial/viewmodel/post_viewmodel.dart';

const Color _primaryColor = Color(0xFF4F46E5);
const Color _mutedColor = Color(0xFF6B7280);
const Color _fieldFillColor = Color(0xFFF3F4F6);

class EditProfileView extends StatefulWidget {
  const EditProfileView({super.key});

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _usernameController;
  late final TextEditingController _bioController;

  final ImagePicker _picker = ImagePicker();
  XFile? _selectedAvatar;
  Uint8List? _selectedAvatarBytes;

  @override
  void initState() {
    super.initState();
    final user = context.read<LoginViewModel>().user;
    _nameController = TextEditingController(text: user?.name ?? '');
    _usernameController = TextEditingController(text: user?.username ?? '');
    _bioController = TextEditingController(text: user?.bio ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (image == null) return;

    final fileSize = await image.length();
    if (fileSize > 5 * 1024 * 1024) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ukuran foto maksimal 5MB.')),
      );
      return;
    }

    final bytes = await image.readAsBytes();
    if (!mounted) return;
    setState(() {
      _selectedAvatar = image;
      _selectedAvatarBytes = bytes;
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final loginVM = context.read<LoginViewModel>();
    final postVM = context.read<PostViewModel>();

    final success = await loginVM.updateProfile(
      name: _nameController.text.trim(),
      username: _usernameController.text.trim(),
      bio: _bioController.text.trim(),
      avatarFilePath: _selectedAvatar?.path,
      avatarBytes: _selectedAvatarBytes,
      avatarFileName: _selectedAvatar?.name,
    );

    if (!mounted) return;

    if (success) {
      final updatedUser = loginVM.user;
      if (updatedUser != null) {
        final uid = int.tryParse(updatedUser.id) ?? 0;
        postVM.syncAuthorInfo(
          userId: uid,
          name: updatedUser.name,
          username: updatedUser.username,
          avatar: updatedUser.avatar,
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil berhasil diperbarui.')),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loginVM.errorMessage ?? 'Gagal memperbarui profil.'),
        ),
      );
    }
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: _mutedColor, fontSize: 13),
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      prefixIcon: Icon(icon, size: 20, color: _mutedColor),
      filled: true,
      fillColor: _fieldFillColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _primaryColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loginVM = context.watch<LoginViewModel>();
    final user = loginVM.user;
    final currentAvatarUrl = user?.fullAvatarUrl ?? '';
    final hasExistingAvatar = currentAvatarUrl.startsWith('http') &&
        !currentAvatarUrl.contains('url-ke-gambar.com');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 20, color: Color(0xFF111827)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Profil',
          style: TextStyle(
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Edit Foto Profil ──────────────────────────────────
              Center(
                child: GestureDetector(
                  onTap: _pickAvatar,
                  child: Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF4F46E5),
                              Color(0xFFEC4899),
                              Color(0xFFF59E0B),
                            ],
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: CircleAvatar(
                            radius: 52,
                            backgroundColor: const Color(0xFFEEF2FF),
                            backgroundImage: _selectedAvatarBytes != null
                                ? MemoryImage(_selectedAvatarBytes!)
                                : (hasExistingAvatar
                                    ? NetworkImage(
                                        currentAvatarUrl,
                                        headers: const {
                                          'ngrok-skip-browser-warning': 'true',
                                        },
                                      ) as ImageProvider
                                    : null),
                            child: (_selectedAvatarBytes == null &&
                                    !hasExistingAvatar)
                                ? const Icon(
                                    Icons.person,
                                    size: 52,
                                    color: _primaryColor,
                                  )
                                : null,
                          ),
                        ),
                      ),
                      Positioned(
                        right: 2,
                        bottom: 2,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _primaryColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.5),
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: TextButton(
                  onPressed: _pickAvatar,
                  child: const Text(
                    'Ubah Foto Profil',
                    style: TextStyle(
                      color: _primaryColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ── Edit Nama ─────────────────────────────────────────
              TextFormField(
                controller: _nameController,
                decoration: _inputDecoration(
                  label: 'Nama Lengkap',
                  hint: 'Masukkan nama lengkap',
                  icon: Icons.person_outline,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nama tidak boleh kosong';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // ── Edit Username ─────────────────────────────────────
              TextFormField(
                controller: _usernameController,
                decoration: _inputDecoration(
                  label: 'Username',
                  hint: 'Masukkan username',
                  icon: Icons.alternate_email,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Username tidak boleh kosong';
                  }
                  if (value.trim().contains(' ')) {
                    return 'Username tidak boleh mengandung spasi';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // ── Edit Bio (Opsional) ───────────────────────────────
              TextFormField(
                controller: _bioController,
                maxLines: 3,
                decoration: _inputDecoration(
                  label: 'Bio',
                  hint: 'Tulis bio singkat tentang dirimu...',
                  icon: Icons.info_outline,
                ),
              ),

              const SizedBox(height: 28),

              // ── Tombol Simpan ─────────────────────────────────────
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: loginVM.isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    disabledBackgroundColor:
                        _primaryColor.withValues(alpha: 0.6),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: loginVM.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Simpan Perubahan',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

