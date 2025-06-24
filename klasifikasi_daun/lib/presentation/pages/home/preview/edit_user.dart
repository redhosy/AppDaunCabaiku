// lib/presentation/pages/profile/edit_user.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:klasifikasi_daun/utils/auth_token_manager.dart';
import 'package:klasifikasi_daun/presentation/widgets/custom_Loading_widget.dart';
import 'package:klasifikasi_daun/services/user_service.dart';

class EditUser extends StatefulWidget {
  const EditUser({super.key});

  @override
  State<EditUser> createState() => _EditUserState();
}

class _EditUserState extends State<EditUser> {
  // Controllers untuk field input
  late TextEditingController _userNameController;
  
  String _userEmail = ''; 
  String? _currentProfilePictureUrl; 
  XFile? _newProfilePictureFile; 

  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _userNameController = TextEditingController();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _userNameController.dispose();
    super.dispose();
  }

  // Debug method untuk mengecek endpoint yang tersedia
  void _debugEndpoints() {
    debugPrint('=== DEBUG API ENDPOINTS ===');
    debugPrint('Current endpoint being called: GET /user');
    debugPrint('Possible alternative endpoints:');
    debugPrint('- GET /users/me');
    debugPrint('- GET /api/user');
    debugPrint('- GET /api/users/me');
    debugPrint('- GET /profile');
    debugPrint('- GET /api/profile');
    debugPrint('=== END DEBUG ===');
  }

  // Fungsi untuk memuat data profil pengguna saat ini
  Future<void> _loadUserProfile() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    // Debug endpoints
    _debugEndpoints();

    try {
      // Coba ambil dari backend terlebih dahulu
      final userData = await _userService.getMyProfileDetails();

      if (mounted) {
        setState(() {
          _userNameController.text = userData['nama'] ?? '';
          _userEmail = userData['email'] ?? 'email@example.com';
          _currentProfilePictureUrl = userData['image'];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error memuat data profil dari API: $e');
      
      // Jika API gagal, gunakan data dari AuthTokenManager sebagai fallback
      try {
        final userName = await AuthTokenManager.getUserName();
        final userEmail = await AuthTokenManager.getEmail();
        final profilePicUrl = await AuthTokenManager.getProfilePictureUrl();

        if (mounted) {
          setState(() {
            _userNameController.text = userName ?? '';
            _userEmail = userEmail ?? 'email@example.com';
            _currentProfilePictureUrl = profilePicUrl;
            _isLoading = false;
          });
        }

        // Tampilkan warning bahwa data diambil dari cache lokal
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('Menggunakan data tersimpan. Periksa koneksi internet.'),
                  ),
                ],
              ),
              backgroundColor: Colors.orange[400],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } catch (fallbackError) {
        debugPrint('Error memuat data dari AuthTokenManager: $fallbackError');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal memuat profil: ${e.toString()}'),
              backgroundColor: Colors.red[400],
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  // Fungsi untuk menampilkan bottom sheet pilihan sumber gambar
  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: SafeArea(
            child: Wrap(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Pilih Sumber Foto',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF38B48B).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Color(0xFF38B48B),
                          ),
                        ),
                        title: const Text('Kamera'),
                        onTap: () {
                          Navigator.pop(context);
                          _pickProfilePicture(ImageSource.camera);
                        },
                      ),
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF38B48B).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.photo_library,
                            color: Color(0xFF38B48B),
                          ),
                        ),
                        title: const Text('Galeri'),
                        onTap: () {
                          Navigator.pop(context);
                          _pickProfilePicture(ImageSource.gallery);
                        },
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Fungsi untuk memilih gambar dari galeri atau kamera
  Future<void> _pickProfilePicture(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: source,
      maxWidth: 1000,
      maxHeight: 1000,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _newProfilePictureFile = pickedFile;
      });
    }
  }

  // Fungsi untuk menyimpan perubahan profil
  Future<void> _saveProfile() async {
    if (!mounted) return;

    // Validasi input
    if (_userNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nama tidak boleh kosong'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Langkah 1: Upload foto profil baru jika ada
      if (_newProfilePictureFile != null) {
        debugPrint('Mengunggah foto profil baru: ${_newProfilePictureFile!.path}');
        final newUrl = await _userService.uploadProfilePicture(_newProfilePictureFile!);
        await AuthTokenManager.saveProfilePictureUrl(newUrl);
        _currentProfilePictureUrl = newUrl;
        debugPrint('Foto profil berhasil diunggah.');
      }

      // Langkah 2: Update nama (tanpa bio)
      debugPrint('Menyimpan perubahan nama...');
      final updatedUserData = await _userService.updateMyProfile(
        nama: _userNameController.text.trim(),
      );

      // Update AuthTokenManager dengan data terbaru
      await AuthTokenManager.saveUserName(updatedUserData['nama'] ?? '');
      await AuthTokenManager.saveProfilePictureUrl(updatedUserData['image'] ?? '');

      debugPrint('Profil berhasil diperbarui.');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Profil berhasil diperbarui!'),
              ],
            ),
            backgroundColor: Colors.green[400],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('Error saat menyimpan profil: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan profil: ${e.toString()}'),
            backgroundColor: Colors.red[400],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildProfilePicture() {
    return Center(
      child: GestureDetector(
        onTap: _showImageSourceDialog,
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 80,
                backgroundColor: Colors.grey[100],
                backgroundImage: _newProfilePictureFile != null
                    ? FileImage(File(_newProfilePictureFile!.path)) as ImageProvider
                    : (_currentProfilePictureUrl != null && _currentProfilePictureUrl!.isNotEmpty
                        ? NetworkImage(_currentProfilePictureUrl!)
                        : null),
                child: (_newProfilePictureFile == null && 
                       (_currentProfilePictureUrl == null || _currentProfilePictureUrl!.isEmpty))
                    ? Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFF38B48B),
                              const Color(0xFF38B48B).withOpacity(0.8),
                            ],
                          ),
                        ),
                        child: Center(
                          child: Text(
                            _userNameController.text.isNotEmpty 
                                ? _userNameController.text[0].toUpperCase() 
                                : '?',
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      )
                    : null,
              ),
            ),
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF38B48B),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(8),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool readOnly = false,
    String? helperText,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        style: TextStyle(
          fontSize: 16,
          color: readOnly ? Colors.grey[600] : const Color(0xFF2D3748),
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          helperText: helperText,
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF38B48B).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF38B48B),
              size: 20,
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF38B48B), width: 2),
          ),
          filled: true,
          fillColor: readOnly ? Colors.grey[50] : Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          labelStyle: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Edit Profil',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2D3748),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const SizedBox(height: 20),
                
                // Profile Picture Section
                _buildProfilePicture(),
                
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    'Ketuk foto untuk mengubah',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                
                const SizedBox(height: 40),

                // Form Section
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Informasi Profil',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Nama Pengguna
                      _buildInputField(
                        controller: _userNameController,
                        label: 'Nama Lengkap',
                        icon: Icons.person_outline,
                        helperText: 'Masukkan nama lengkap Anda',
                      ),
                      
                      const SizedBox(height: 20),

                      // Email (Read-only)
                      _buildInputField(
                        controller: TextEditingController(text: _userEmail),
                        label: 'Email',
                        icon: Icons.email_outlined,
                        readOnly: true,
                        helperText: 'Email tidak dapat diubah',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Save Button
                Container(
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Color(0xFF38B48B),
                        Color(0xFF2D9A6B),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF38B48B).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.save_outlined,
                                color: Colors.white,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Simpan Perubahan',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                
                const SizedBox(height: 40),
              ],
            ),
          ),
          
          // Loading overlay
          if (_isLoading)
            const LoadingWidget(
              message: "Menyimpan perubahan...",
            ),
        ],
      ),
    );
  }
}