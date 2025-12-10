import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;
  
  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<_OnboardingPage> _pages = [
    _OnboardingPage(
      icon: '🎵',
      title: 'Buat Musik dengan AI',
      description: 'Wujudkan ide musikmu hanya dengan menuliskan lirik dan memilih genre. AI akan membuat musik untukmu!',
      gradient: [Color(0xFF84CC16), Color(0xFF22C55E)],
    ),
    _OnboardingPage(
      icon: '🎨',
      title: '120+ Genre Tersedia',
      description: 'Pop, Rock, EDM, Dangdut, K-Pop, Jazz, dan masih banyak lagi. Pilih sesuai seleramu!',
      gradient: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
    ),
    _OnboardingPage(
      icon: '📱',
      title: 'Dengarkan Dimana Saja',
      description: 'Putar musik di background, download ke perangkat, dan nikmati musikmu kapan saja!',
      gradient: [Color(0xFF3B82F6), Color(0xFF06B6D4)],
    ),
    _OnboardingPage(
      icon: '✨',
      title: 'Siap Berkreasi?',
      description: 'Mari mulai perjalanan musikmu bersama Lumina AI. Kreativitas tanpa batas!',
      gradient: [Color(0xFFF97316), Color(0xFFEAB308)],
    ),
  ];

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Pages
          PageView.builder(
            controller: _controller,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              final page = _pages[index];
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: page.gradient,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Spacer(),
                        Text(page.icon, style: const TextStyle(fontSize: 100)),
                        const SizedBox(height: 40),
                        Text(
                          page.title,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          page.description,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.9),
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const Spacer(),
                        const Spacer(),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          
          // Bottom controls
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Page indicators
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_pages.length, (index) {
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentPage == index ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _currentPage == index 
                                ? Colors.white 
                                : Colors.white.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 32),
                    
                    // Buttons
                    Row(
                      children: [
                        if (_currentPage > 0)
                          Expanded(
                            child: TextButton(
                              onPressed: () {
                                _controller.previousPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              },
                              child: const Text(
                                'Kembali',
                                style: TextStyle(color: Colors.white, fontSize: 16),
                              ),
                            ),
                          )
                        else
                          Expanded(
                            child: TextButton(
                              onPressed: _completeOnboarding,
                              child: Text(
                                'Lewati',
                                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 16),
                              ),
                            ),
                          ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () {
                              if (_currentPage < _pages.length - 1) {
                                _controller.nextPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              } else {
                                _completeOnboarding();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              _currentPage < _pages.length - 1 ? 'Lanjut' : 'Mulai Sekarang',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingPage {
  final String icon;
  final String title;
  final String description;
  final List<Color> gradient;

  _OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
    required this.gradient,
  });
}
