import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'router/app_router.dart';
import 'package:sukh_app/services/notification_service.dart';
import 'package:sukh_app/services/session_service.dart';
import 'package:sukh_app/services/connectivity_service.dart';
import 'package:sukh_app/services/shake_service.dart';
import 'package:sukh_app/services/theme_service.dart';
import 'package:sukh_app/widgets/shake_hint_overlay.dart';
import 'package:sukh_app/widgets/snow_effect.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:provider/provider.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await NotificationService.initialize();

  await SessionService.checkAndHandleSession();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final ConnectivityService _connectivityService = ConnectivityService();
  final ThemeService _themeService = ThemeService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Connectivity service will be initialized after first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (navigatorKey.currentContext != null) {
        _connectivityService.initialize(navigatorKey.currentContext!);
        // Initialize shake detection after context is ready
        ShakeService.initialize();
      }
    });
  }

  @override
  void dispose() {
    _connectivityService.dispose();
    ShakeService.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      // Re-initialize shake detection when app resumes
      ShakeService.initialize();

      SessionService.checkAndHandleSession().then((isValid) {
        if (!isValid && mounted) {
          appRouter.refresh();
        }
      });
    } else if (state == AppLifecycleState.paused) {
      // Optionally stop shake detection when app is paused to save battery
      // ShakeService.stop();
    }
  }

  bool _isDecember() {
    final now = DateTime.now();
    // Stop snowfall after December 31
    if (now.month == 12 && now.day <= 31) {
      return true;
    }
    return false;
  }

  ThemeData _buildLightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: AppColors.deepGreen,
      scaffoldBackgroundColor:
          Colors.transparent, // Transparent to show gradient
      useMaterial3: true, // Modern Material 3 design
      colorScheme: ColorScheme.light(
        primary: AppColors.deepGreen,
        secondary: AppColors.deepGreenAccent,
        surface: const Color.fromARGB(255, 177, 243, 183),
        background: const Color.fromARGB(255, 137, 238, 117),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.lightTextPrimary,
        onBackground: AppColors.lightTextPrimary,
        outline: AppColors.lightInputGray,
      ),
      textTheme: TextTheme(
        bodyMedium: TextStyle(
          fontWeight: FontWeight.w400,
          color: AppColors.lightTextPrimary,
          fontSize: 24, // Increased from 18 for better readability
        ),
        bodyLarge: TextStyle(
          color: AppColors.lightTextPrimary,
          fontSize: 26, // Increased from 20
          fontWeight: FontWeight.w400,
        ),
        bodySmall: TextStyle(
          color: AppColors.lightTextSecondary,
          fontSize: 20,
        ), // Increased from 16
        titleLarge: TextStyle(
          color: AppColors.lightTextPrimary,
          fontSize: 36, // Increased from 28
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: AppColors.lightTextPrimary,
          fontSize: 28, // Increased from 22
          fontWeight: FontWeight.w600,
        ),
        titleSmall: TextStyle(
          color: AppColors.lightTextSecondary,
          fontSize: 24, // Increased from 18
          fontWeight: FontWeight.w500,
        ),
        labelLarge: TextStyle(
          color: AppColors.lightTextPrimary,
          fontSize: 24, // Increased from 18
          fontWeight: FontWeight.w500,
        ),
      ),
      iconTheme: IconThemeData(color: AppColors.deepGreen, size: 24),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent, // Transparent to show gradient
        foregroundColor: AppColors.getDeepGreen(false), // false = light mode
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.getDeepGreen(false), // false = light mode
          fontSize: 26, // Increased from 20 for better readability
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightSurface,
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.lightBorderColor, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.lightInputGray),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.lightInputGray),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.deepGreen, width: 2),
        ),
        labelStyle: TextStyle(
          color: AppColors.lightTextSecondary,
          fontSize: 20, // Increased from 16 for better readability
        ),
        hintStyle: TextStyle(
          color: AppColors.lightTextSecondary,
          fontSize: 20, // Increased from 16
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.deepGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
          textStyle: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ), // Increased from 18
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      fontFamily: 'Inter',
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: AppColors.deepGreen,
      scaffoldBackgroundColor: AppColors.darkBackground,
      useMaterial3: true, // Modern Material 3 design
      colorScheme: ColorScheme.dark(
        primary: AppColors.deepGreen,
        secondary: AppColors.deepGreenAccent,
        surface: AppColors.darkSurface,
        background: AppColors.darkBackground,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.darkTextPrimary,
        onBackground: AppColors.darkTextPrimary,
        outline: AppColors.darkInputGray,
      ),
      textTheme: TextTheme(
        bodyMedium: TextStyle(
          fontWeight: FontWeight.w400,
          color: AppColors.darkTextPrimary,
          fontSize: 18,
        ),
        bodyLarge: TextStyle(
          color: AppColors.darkTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w400,
        ),
        bodySmall: TextStyle(color: AppColors.darkTextSecondary, fontSize: 16),
        titleLarge: TextStyle(
          color: AppColors.darkTextPrimary,
          fontSize: 28,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: AppColors.darkTextPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
        titleSmall: TextStyle(
          color: AppColors.darkTextSecondary,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
        labelLarge: TextStyle(
          color: AppColors.darkTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
      ),
      iconTheme: IconThemeData(color: AppColors.darkTextPrimary, size: 24),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkBackground,
        foregroundColor: AppColors.getDeepGreen(true), // true = dark mode
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.getDeepGreen(true), // true = dark mode
          fontSize: 26, // Increased from 20 for better readability
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.darkBorderColor, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.darkInputGray),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.darkInputGray),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.deepGreen, width: 2),
        ),
        labelStyle: TextStyle(
          color: AppColors.darkTextSecondary,
          fontSize: 20, // Increased from 16 for better readability
        ),
        hintStyle: TextStyle(
          color: AppColors.darkTextSecondary,
          fontSize: 20, // Increased from 16
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.deepGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
          textStyle: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ), // Increased from 18
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      fontFamily: 'Inter',
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _themeService,
      child: Consumer<ThemeService>(
        builder: (context, themeService, _) {
          return ScreenUtilInit(
            designSize: const Size(375, 812),
            minTextAdapt: true,
            splitScreenMode: true,
            builder: (context, child) {
              final isDark = themeService.isDarkMode;
              return GestureDetector(
                onTap: () {
                  FocusManager.instance.primaryFocus?.unfocus();
                },
                behavior: HitTestBehavior.translucent,
                child: Container(
                  // Background with pattern image and gradient
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [AppColors.darkBackground, AppColors.darkBackground]
                          : AppColors.getGradientColors(
                              false,
                            ), // Light mode gradient
                      stops: isDark
                          ? const [0.0, 1.0]
                          : const [
                              0.0,
                              0.3,
                              0.6,
                              0.8,
                              1.0,
                            ], // Multiple stops for smooth gradient
                    ),
                    image: DecorationImage(
                      image: const AssetImage(
                        'lib/assets/img/main_background.png',
                      ),
                      fit: BoxFit.none,
                      scale: 3,
                      opacity: isDark ? 0.3 : 0.1, // Very subtle in light mode
                    ),
                  ),
                  child: _isDecember()
                      ? SnowEffect(
                          child: MaterialApp.router(
                            debugShowCheckedModeBanner: false,
                            routerConfig: appRouter,
                            theme: _buildLightTheme(),
                            darkTheme: _buildDarkTheme(),
                            themeMode: themeService.themeMode,
                            builder: (context, child) {
                              return ShakeHintOverlay(
                                child: child ?? const SizedBox.shrink(),
                              );
                            },
                          ),
                        )
                      : MaterialApp.router(
                          debugShowCheckedModeBanner: false,
                          routerConfig: appRouter,
                          theme: _buildLightTheme(),
                          darkTheme: _buildDarkTheme(),
                          themeMode: themeService.themeMode,
                          builder: (context, child) {
                            return ShakeHintOverlay(
                              child: child ?? const SizedBox.shrink(),
                            );
                          },
                        ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
