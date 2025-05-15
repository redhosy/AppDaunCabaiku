import 'package:flutter/material.dart';
import 'package:klasifikasi_daun/presentation/pages/auth/login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingContent> _contents = [
    OnboardingContent(
      title: 'Pantau kondisi tanaman cabaimu dengan lebih mudah dan cepat.',
      image: 'assets/onboarding1.png',
    ),
    OnboardingContent(
      title: 'Kenali gejala sejak dini untuk hasil panen yang maksimal.',
      image: 'assets/onboarding2.png',
    ),
    OnboardingContent(
      title: 'Ayo Cek Kesehatan Cabai Mu Dari Daunnya',
      image: 'assets/onboarding3.png',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _navigateToNext() async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (_currentPage < _contents.length - 1) {
      _pageController.nextPage(
          duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder:(_) => LoginPage()));
    }
  }

  void _skip() {
    _pageController.jumpToPage(_contents.length - 1);
  }

  void _onPageChange(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Text(
                  'CapsiCheck',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFEF9651),
                  ),
                ),
                const SizedBox(width: 42),
                Image.asset('assets/Portal.png', scale: 2),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChange,
                itemCount: _contents.length,
                itemBuilder: (context, index) {
                  return Column(
                    children: [
                      Expanded(
                        child: index == 0
                            ? _buildPlaceholderImage1()
                            : index == 1
                                ? _buildPlaceholderImage2()
                                : _buildPlaceholderImage3(),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 32, 12, 20),
                        child: Text(
                          _contents[index].title,
                          style: const TextStyle(
                            fontSize: 18,
                            color: Color(0xFF3F7D58),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _contents.length,
                  (index) => buildIndicator(index == _currentPage),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              margin: const EdgeInsets.only(bottom: 30),
              child: _currentPage == _contents.length - 1
                  ? ElevatedButton(
                      onPressed: _navigateToNext,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3F7D58),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 50, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Mulai',
                        style: TextStyle(fontSize: 14),
                      ),
                    )
                  : ElevatedButton(
                      onPressed: _skip,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF3F7D58),
                        side: const BorderSide(color: Color(0xFF3F7D58)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 50, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Skip',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildIndicator(bool isActive) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5),
      height: 10,
      width: isActive ? 25 : 10,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF3F7D58) : const Color(0xFFD9D9D9),
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }

  Widget _buildPlaceholderImage1() {
    return Image.asset(
      'assets/onboarding1.png',
      scale: 1.2,
    );
  }

  Widget _buildPlaceholderImage2() {
    return Image.asset('assets/onboarding2.png', scale: 1.2);
  }

  Widget _buildPlaceholderImage3() {
    return Image.asset('assets/onboarding3.png', scale: 1.2);
  }
}

class OnboardingContent {
  final String title;
  final String image;

  OnboardingContent({required this.title, required this.image});
}
