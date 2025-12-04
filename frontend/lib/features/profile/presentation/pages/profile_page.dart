import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sagawa_pos_new/core/constants/app_constants.dart';
import 'package:sagawa_pos_new/core/services/permission_service.dart';
import 'package:sagawa_pos_new/core/utils/responsive_helper.dart';
import 'package:sagawa_pos_new/core/widgets/custom_snackbar.dart';
import 'package:sagawa_pos_new/data/services/user_service.dart';
import 'package:sagawa_pos_new/features/profile/domain/models/user_model.dart';
import 'package:sagawa_pos_new/shared/widgets/shimmer_loading.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  UserModel? _user;
  bool _isLoading = true;
  bool _isSaving = false;
  File? _selectedImage;

  // Controllers for editable fields
  late TextEditingController _usernameController;
  late TextEditingController _kemitraanController;
  late TextEditingController _outletController;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
    _kemitraanController = TextEditingController();
    _outletController = TextEditingController();
    _loadUserData();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _kemitraanController.dispose();
    _outletController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    final user = await UserService.getUser();
    setState(() {
      _user = user;
      if (user != null) {
        _usernameController.text = user.username;
        _kemitraanController.text = user.hasSubBrand && user.subBrand != null
            ? '${user.kemitraan} - ${user.subBrand}'
            : user.kemitraan;
        _outletController.text = user.outlet;
      }
      _isLoading = false;
    });
  }

  Future<void> _saveProfile() async {
    if (_user == null) return;

    setState(() => _isSaving = true);

    try {
      // Parse kemitraan and subBrand from the combined field
      String kemitraan = _kemitraanController.text.trim();
      String? subBrand;

      if (kemitraan.contains(' - ')) {
        final parts = kemitraan.split(' - ');
        kemitraan = parts[0].trim();
        subBrand = parts.length > 1 ? parts[1].trim() : null;
      }

      final updatedUser = _user!.copyWith(
        username: _usernameController.text.trim(),
        kemitraan: kemitraan,
        outlet: _outletController.text.trim(),
        subBrand: subBrand ?? _user!.subBrand,
      );

      // Update to backend
      final result = await UserService.updateProfileToBackend(updatedUser);

      if (!mounted) return;

      if (result != null) {
        setState(() {
          _user = result;
        });
        CustomSnackbar.show(
          context,
          message: 'Profil berhasil disimpan',
          type: SnackbarType.success,
        );
      } else {
        CustomSnackbar.show(
          context,
          message: 'Gagal menyimpan profil ke server',
          type: SnackbarType.error,
        );
      }
    } catch (e) {
      if (!mounted) return;
      CustomSnackbar.show(
        context,
        message: 'Gagal menyimpan profil: $e',
        type: SnackbarType.error,
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    // Request permission based on source
    bool hasPermission = false;
    if (source == ImageSource.camera) {
      hasPermission = await PermissionService.requestCameraPermission(context);
    } else {
      hasPermission = await PermissionService.requestStoragePermission(context);
    }

    if (!hasPermission) {
      return;
    }

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        final File imageFile = File(image.path);
        final bytes = await imageFile.readAsBytes();
        final base64Image = base64Encode(bytes);

        setState(() {
          _selectedImage = imageFile;
        });

        if (_user != null) {
          final updatedUser = UserModel(
            id: _user!.id,
            username: _user!.username,
            kemitraan: _user!.kemitraan,
            outlet: _user!.outlet,
            subBrand: _user!.subBrand,
            profilePhotoUrl: _user!.profilePhotoUrl,
            profilePhotoData: base64Image, // Save pure base64, no prefix
            role: _user!.role,
          );

          await UserService.updateUser(updatedUser);
          await _loadUserData();

          if (!mounted) return;
          CustomSnackbar.show(
            context,
            message: 'Foto profil berhasil diperbarui',
            type: SnackbarType.success,
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      CustomSnackbar.show(
        context,
        message: 'Gagal memilih foto: $e',
        type: SnackbarType.error,
      );
    }
  }

  String _cleanBase64(String base64String) {
    if (base64String.contains(',')) {
      return base64String.split(',').last;
    }
    return base64String;
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Pilih Sumber Foto',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFFFF4B4B)),
              title: const Text('Kamera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library,
                color: Color(0xFFFF4B4B),
              ),
              title: const Text('Galeri'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? const _ProfilePageSkeleton()
          : _user == null
          ? const Center(
              child: Text(
                'Data pengguna tidak ditemukan',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : Column(
              children: [
                // Header with gradient background
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFFF4B4B), Color(0xFFFF4B4B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      child: Column(
                        children: [
                          // Back button and Title
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () => Navigator.of(context).pop(),
                                child: SvgPicture.asset(
                                  AppImages.backArrow,
                                  width: 24,
                                  height: 24,
                                  colorFilter: const ColorFilter.mode(
                                    Colors.white,
                                    BlendMode.srcIn,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Akun',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 43),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Two column layout: Photo + User Info
                          Row(
                            children: [
                              // Profile Photo with Camera Button
                              Stack(
                                children: [
                                  Container(
                                    width: 120,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 1,
                                      ),
                                    ),
                                    child: ClipOval(
                                      child: _selectedImage != null
                                          ? Image.file(
                                              _selectedImage!,
                                              fit: BoxFit.cover,
                                            )
                                          : _user!.profilePhotoData != null &&
                                                _user!
                                                    .profilePhotoData!
                                                    .isNotEmpty
                                          ? Image.memory(
                                              base64Decode(
                                                _cleanBase64(
                                                  _user!.profilePhotoData!,
                                                ),
                                              ),
                                              fit: BoxFit.cover,
                                            )
                                          : Container(
                                              color: Colors.white,
                                              child: const Icon(
                                                Icons.person,
                                                size: 60,
                                                color: Color(0xFFFF4B4B),
                                              ),
                                            ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: GestureDetector(
                                      onTap: _showImageSourceDialog,
                                      child: Container(
                                        width: 30,
                                        height: 30,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 1,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.camera_alt,
                                          color: Colors.black,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 20),

                              // Username and ID Column
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Username
                                    Text(
                                      _user!.username,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),

                                    // User ID
                                    Text(
                                      _user!.id,
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.95),
                                        fontSize: 16,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Form Fields
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // User ID Field
                        _ProfileField(
                          label: 'User ID',
                          controller: TextEditingController(text: _user!.id),
                          isLocked: true,
                        ),
                        const SizedBox(height: 24),

                        // Nama Field
                        _ProfileField(
                          label: 'Nama',
                          controller: _usernameController,
                          isLocked: false,
                        ),
                        const SizedBox(height: 24),

                        // Kemitraan Field (combined with Sub Brand if exists)
                        _ProfileField(
                          label: 'Kemitraan',
                          controller: _kemitraanController,
                          isLocked: false,
                        ),
                        const SizedBox(height: 24),

                        // Outlet Field
                        _ProfileField(
                          label: 'Outlet',
                          controller: _outletController,
                          isLocked: false,
                        ),
                      ],
                    ),
                  ),
                ),

                // Save Button - Sticky Bottom
                Container(
                  padding: const EdgeInsets.only(
                    left: 20,
                    top: 2,
                    right: 20,
                    bottom: 10,
                  ),
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.0),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF4B4B),
                          disabledBackgroundColor: const Color(
                            0xFFFF4B4B,
                          ).withOpacity(0.6),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                'Simpan',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _ProfileField extends StatefulWidget {
  const _ProfileField({
    required this.label,
    required this.controller,
    this.isLocked = false,
  });

  final String label;
  final TextEditingController controller;
  final bool isLocked;

  @override
  State<_ProfileField> createState() => _ProfileFieldState();
}

class _ProfileFieldState extends State<_ProfileField> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isFocused ? const Color(0xFFFF4B4B) : Colors.black,
              width: 1.5,
            ),
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            enabled: !widget.isLocked,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black,
              fontWeight: FontWeight.w400,
            ),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              border: InputBorder.none,
              suffixIcon: widget.isLocked
                  ? const Icon(Icons.lock, color: Color(0xFF757575), size: 20)
                  : null,
            ),
          ),
        ),
        // Label on border top-left
        Positioned(
          left: 12,
          top: -10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            color: Colors.white,
            child: Text(
              widget.label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Skeleton loading untuk profile page dengan efek shimmer
class _ProfilePageSkeleton extends StatelessWidget {
  const _ProfilePageSkeleton();

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Column(
        children: [
          // Header
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Column(
                  children: [
                    // App bar
                    Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: Container(
                              width: 60,
                              height: 20,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Profile photo and info
                    Row(
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 150,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                width: 120,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Form Fields
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _buildFieldSkeleton(),
                  const SizedBox(height: 24),
                  _buildFieldSkeleton(),
                  const SizedBox(height: 24),
                  _buildFieldSkeleton(),
                  const SizedBox(height: 24),
                  _buildFieldSkeleton(),
                ],
              ),
            ),
          ),

          // Save button
          Padding(
            padding: const EdgeInsets.all(20),
            child: Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldSkeleton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: double.infinity,
        height: 20,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}
