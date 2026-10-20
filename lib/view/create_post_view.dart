import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:zisocial/viewmodel/create_post_viewmodel.dart';
import 'package:zisocial/viewmodel/login_viewmodel.dart';
import 'package:zisocial/widget/app_button.dart';
import 'package:zisocial/widget/app_text_field.dart';

class CreatePostView extends StatefulWidget {
  const CreatePostView({super.key});

  @override
  State<CreatePostView> createState() => _CreatePostViewState();
}

class _CreatePostViewState extends State<CreatePostView> {
  final _captionController = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  XFile? _selectedImage;

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );

    if (image == null) {
      return;
    }

    final file = File(image.path);

    final fileSize = await file.length();

    // Maksimal 5 MB
    if (fileSize > 5 * 1024 * 1024) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Ukuran gambar maksimal 5MB.',
          ),
        ),
      );

      return;
    }

    // Cek ekstensi file
    final extension = image.path
        .split('.')
        .last
        .toLowerCase();

    if (extension != 'jpg' && extension != 'jpeg') {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Hanya gambar JPG yang diperbolehkan.',
          ),
        ),
      );

      return;
    }

    setState(() {
      _selectedImage = image;
    });
  }

  Future<void> _createPost() async {
    // Pastikan gambar sudah dipilih
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Silakan pilih gambar terlebih dahulu.',
          ),
        ),
      );

      return;
    }

    // Ambil user yang sedang login
    final user = context.read<LoginViewModel>().user;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'User belum login.',
          ),
        ),
      );

      return;
    }

    // Kirim postingan ke API
    final success = await context
        .read<CreatePostViewModel>()
        .createPost(
          userId: int.parse(user.id),
          imagePath: _selectedImage!.path,
          caption: _captionController.text.trim(),
        );

    if (!mounted) return;

    if (success) {
      final message = context
              .read<CreatePostViewModel>()
              .successMessage ??
          'Postingan berhasil dibuat.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );

      // Kembali ke Home
      Navigator.pop(context);
    } else {
      final message = context
              .read<CreatePostViewModel>()
              .errorMessage ??
          'Gagal membuat postingan.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading =
        context.watch<CreatePostViewModel>().isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buat Postingan'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Preview gambar
            if (_selectedImage != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(_selectedImage!.path),
                  height: 300,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              )
            else
              Container(
                height: 300,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey,
                  ),
                ),
                child: const Center(
                  child: Text(
                    'Belum ada gambar',
                  ),
                ),
              ),

            const Gap(16),

            // Tombol pilih gambar
            OutlinedButton.icon(
              onPressed: isLoading
                  ? null
                  : _pickImage,
              icon: const Icon(
                Icons.image_outlined,
              ),
              label: const Text(
                'Pilih Gambar',
              ),
            ),

            const Gap(16),

            // Caption
            AppTextField(
              controller: _captionController,
              labelText: 'Caption',
              hintText: 'Tulis caption...',
              prefixIcon: const Icon(
                Icons.edit_outlined,
              ),
            ),

            const Gap(24),

            // Tombol posting
            AppButton(
              text: 'Posting',
              isLoading: isLoading,
              onPressed: _createPost,
            ),
          ],
        ),
      ),
    );
  }
}