import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'package:sukh_app/services/storage_service.dart';
import 'package:sukh_app/services/api_service.dart';
import 'package:sukh_app/services/biometric_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final seenOnboarding = prefs.getBool('seenOnboarding') ?? false;

  runApp(MyApp(seenOnboarding: seenOnboarding));
}

class MyApp extends StatelessWidget {
  final bool seenOnboarding;
  const MyApp({super.key, required this.seenOnboarding});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: seenOnboarding ? HomePage() : OnboardingScreen(),
    );
  }
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _dontShowAgain = false;

  final List<Map<String, String>> onboardingData = [
    {
      "title": "Гар ажиллагаатай процессуудад баяртай гэж хэлээрэй.",
      "description": "This app will make your life easier.",
      "image": "lib/assets/img/neg.jpg",
    },
  ];

  void _finishOnboarding() async {
    // Update local storage
    await StorageService.setTaniltsuulgaKharakhEsekh(false);

    // If checkbox is checked, update backend
    if (_dontShowAgain) {
      try {
        await ApiService.updateTaniltsuulgaKharakhEsekh(
          taniltsuulgaKharakhEsekh: false,
        );
      } catch (e) {
        print('Error updating taniltsuulgaKharakhEsekh in backend: $e');
      }

      // Also keep the old seenOnboarding for backwards compatibility if needed
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('seenOnboarding', true);
    }

    if (mounted) {
      // Check if biometric is available
      final biometricAvailable = await BiometricService.isAvailable();
      final prefs = await SharedPreferences.getInstance();
      final hasSeenBiometricOnboarding =
          prefs.getBool('hasSeenBiometricOnboarding') ?? false;

      // If biometric is available and user hasn't seen the onboarding, show biometric onboarding
      if (biometricAvailable && !hasSeenBiometricOnboarding) {
        context.go('/hoyrdah');
      } else {
        context.go('/nuur');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: onboardingData.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) {
              return Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(onboardingData[index]['image']!),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.3),
                        Colors.black.withValues(alpha: 0.6),
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        onboardingData[index]['title']!,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _dontShowAgain = !_dontShowAgain;
                        });
                      },
                      child: const Text(
                        "Дахин харуулахгүй байх",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _dontShowAgain = !_dontShowAgain;
                        });
                      },
                      icon: Icon(
                        _dontShowAgain
                            ? Icons.check_box
                            : Icons.check_box_outline_blank,
                        color: Colors.white,
                        size: 30,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                // Continue button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_currentPage == onboardingData.length - 1) {
                        _finishOnboarding();
                      } else {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeIn,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      _currentPage == onboardingData.length - 1
                          ? "Эхлэх"
                          : "Үргэлжлүүлэх",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Checkbox
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Home Page")),
      body: const Center(
        child: Text("Welcome to the app!", style: TextStyle(fontSize: 24)),
      ),
    );
  }
}
