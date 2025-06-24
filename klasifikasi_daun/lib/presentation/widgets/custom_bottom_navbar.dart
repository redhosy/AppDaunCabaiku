import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:klasifikasi_daun/presentation/pages/camera/CameraPage.dart';

class PerfectBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const PerfectBottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // Custom painted bottom bar with cut-out circle
          CustomPaint(
            size: const Size(double.infinity, 65),
            painter: BottomBarPainter(),
            child: SizedBox(
              height: 65,
              child: Row(
                children: [
                  Expanded(
                    child: _buildNavButton(
                      icon: Icons.home_outlined,
                      activeIcon: Icons.home,
                      label: 'Home',
                      index: 0,
                      isLeft: true,
                    ),
                  ),
                  const SizedBox(width: 100), // Space for floating button
                  Expanded(
                    child: _buildNavButton(
                      icon: Icons.person_outline,
                      activeIcon: Icons.person,
                      label: 'Profile',
                      index: 1,
                      isLeft: false,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Floating scan button
          Positioned(
            top: -8,
            child: GestureDetector(
              onTap: () async {
                // Navigasi ke halaman kamera saat tombol scan ditekan
                var cameras = await availableCameras();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CameraPage(cameras: cameras),
                  ),
                );
              },
              child: Container(
                width: 65,
                height: 65,
                decoration: const BoxDecoration(
                  color: Color(0xFF3F7D58),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.camera_alt_outlined,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
    required bool isLeft,
  }) {
    bool isActive = currentIndex == index;

    return GestureDetector(
      onTap: () => onTap(index),
      child: Container(
        padding: EdgeInsets.only(
          left: isLeft ? 25 : 10,
          right: isLeft ? 10 : 25,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? Colors.white : Colors.white.withOpacity(0.7),
              size: 24,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.white.withOpacity(0.7),
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom painter for subtracting circle from bottom bar background
class BottomBarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = const Color(0xFF3F7D58);

    final Path fullPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final Offset circleCenter = Offset(size.width / 2, 0);
    final Path circlePath = Path()
      ..addOval(Rect.fromCircle(center: circleCenter, radius: 40));

    final Path finalPath = Path.combine(
      PathOperation.difference,
      fullPath,
      circlePath,
    );

    canvas.drawPath(finalPath, paint);

    // Optional: Add shadow
    canvas.drawShadow(finalPath, Colors.black.withOpacity(0.2), 8.0, true);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
