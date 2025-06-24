// lib/presentation/pages/home/profile/profile_page.dart
import 'package:flutter/material.dart';
import 'package:klasifikasi_daun/presentation/pages/home/preview/edit_user.dart';
import 'package:klasifikasi_daun/presentation/pages/home/preview/tentang_app.dart'; // FIX: Jika AboutAppPage di file terpisah
import 'package:klasifikasi_daun/presentation/pages/home/history/history_page.dart'; // Import HistoryPage
import 'package:klasifikasi_daun/utils/auth_token_manager.dart';
import 'package:klasifikasi_daun/services/auth_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with TickerProviderStateMixin {
  String _userName = 'Memuat...';
  String _userEmail = 'Memuat...';
  String? _profilePictureUrl;
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadUserProfile();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userName = await AuthTokenManager.getUserName();
      final userEmail = await AuthTokenManager.getEmail();
      final profilePicUrl = await AuthTokenManager.getProfilePictureUrl();
      // FIX: Ambil bio juga jika Anda menampilkannya di halaman profil utama
      // final userBio = await AuthTokenManager.getUserBio();

      if (mounted) {
        setState(() {
          _userName = userName ?? 'Pengguna Tidak Dikenal';
          _userEmail = userEmail ?? 'email@tidakdikenal.com';
          _profilePictureUrl = profilePicUrl;
          // _userBio = userBio; // Set user bio
          _isLoading = false;
        });
        _animationController.forward(); // Mulai animasi setelah data dimuat
      }
    } catch (e) {
      debugPrint("Error memuat profil user: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _userEmail = 'Error memuat...';
          _userName = 'Error memuat...';
        });
        _animationController.forward(); // Mulai animasi meskipun ada error
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memuat profil: ${e.toString()}'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Widget _buildModernMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color:
                        (iconColor ?? const Color(0xFF38B48B)).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor ?? const Color(0xFF38B48B),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1D29),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    // FIX: Menggunakan const Icon
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB), // Warna latar belakang
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF38B48B), Color(0xFF269C7E)],
            ),
          ),
        ),
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(40),
            bottomRight: Radius.circular(40),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF38B48B),
                strokeWidth: 3,
              ),
            )
          : FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      expandedHeight: 240, // Tinggi AppBar saat expanded
                      floating: false,
                      pinned: true,
                      elevation: 0,
                      backgroundColor: Colors.transparent,
                      flexibleSpace: FlexibleSpaceBar(
                        background: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0xFF38B48B), Color(0xFF269C7E)],
                            ),
                          ),
                          child: SafeArea(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                      width: 4,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 20,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: CircleAvatar(
                                    radius: 50,
                                    backgroundColor:
                                        Colors.white.withOpacity(0.2),
                                    // FIX UTAMA: Menampilkan foto profil atau inisial
                                    backgroundImage:
                                        _profilePictureUrl != null &&
                                                _profilePictureUrl!.isNotEmpty
                                            ? NetworkImage(_profilePictureUrl!)
                                                as ImageProvider
                                            : null,
                                    child: _profilePictureUrl == null ||
                                            _profilePictureUrl!.isEmpty
                                        ? Text(
                                            _userName.isNotEmpty
                                                ? _userName[0].toUpperCase()
                                                : '?',
                                            style: const TextStyle(
                                              fontSize: 32,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          )
                                        : null,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // User Name
                                Text(
                                  _userName,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                // User Email
                                Text(
                                  _userEmail,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        collapseMode: CollapseMode
                            .pin, // Keep content pinned at top when collapsed
                      ),
                      automaticallyImplyLeading:
                          false, // Hapus ikon kembali otomatis
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [

                            // Menu Items
                            _buildModernMenuItem(
                              icon: Icons.person_outline_rounded,
                              title: 'Edit Profil',
                              subtitle: 'Ubah informasi pribadi Anda',
                              onTap: () async {
                                debugPrint('Edit Profil ditekan');
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => const EditUser()),
                                );
                                if (result == true) {
                                  _loadUserProfile(); // Muat ulang profil jika ada perubahan
                                }
                              },
                            ),

                            _buildModernMenuItem(
                              icon: Icons.history_rounded,
                              title: 'Riwayat Scan',
                              subtitle: 'Lihat hasil scan sebelumnya',
                              iconColor: const Color(0xFF6366F1),
                              onTap: () async {
                                debugPrint('Riwayat Scan ditekan');
                                await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const HistoryPage()));
                              },
                            ),

                            _buildModernMenuItem(
                              icon: Icons.info_outline_rounded,
                              title: 'Tentang Aplikasi',
                              subtitle: 'Informasi aplikasi dan versi',
                              iconColor: const Color(0xFF8B5CF6),
                              onTap: () async {
                                debugPrint('Tentang Aplikasi ditekan');
                                // FIX: Asumsi AboutAppPage adalah kelas terpisah
                                await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const AboutAppPage()));
                              },
                            ),

                            const SizedBox(height: 20),

                            // Logout Button
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.red.shade200,
                                  width: 1,
                                ),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () async {
                                    debugPrint('Logout ditekan');
                                    final shouldLogout = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                        title: const Text('Konfirmasi Logout'),
                                        content: const Text(
                                            'Apakah Anda yakin ingin keluar dari aplikasi?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            child: const Text('Batal'),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            style: TextButton.styleFrom(
                                              foregroundColor: Colors.red,
                                            ),
                                            child: const Text('Logout'),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (shouldLogout == true) {
                                      AuthService.logout(context);
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(16),
                                  child: Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.logout_rounded,
                                          color: Colors.red.shade600,
                                          size: 24,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          'Keluar',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.red.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 100),
                          ],
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
