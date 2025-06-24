import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class LoadingWidget extends StatefulWidget {
  final String? message;

  const LoadingWidget({Key? key, this.message}) : super(key: key);

  @override
  State<LoadingWidget> createState() => _LoadingWidgetState();
}

class _LoadingWidgetState extends State<LoadingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2), // Durasi satu siklus animasi
    )..repeat(reverse: true); // Ulangi animasi maju-mundur

    _animation = Tween<double>(begin: 0.8, end: 1.2).animate(
      // Animasi skala dari 0.8 ke 1.2
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      // Memastikan widget menutupi seluruh layar
      child: Container(
        color: Colors.black.withOpacity(0.7), // Semi-transparent overlay
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // FIX UTAMA: Ganti CircularProgressIndicator dengan animasi kustom
              AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _animation.value,
                    child: Lottie.asset(
                      'assets/loading.json', 
                      width: 80,
                      height: 80,
                      fit: BoxFit.fill,
                    ),
                  );
                },
              ),
              // Contoh lain jika Anda ingin Lottie (perlu package lottie)

              if (widget.message != null) ...[
                const SizedBox(height: 20),
                Text(
                  widget.message!,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
