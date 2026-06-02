import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:media_kit/media_kit.dart';
import 'router/app_router.dart';
import 'package:sukh_app/services/notification_service.dart';
import 'package:sukh_app/services/session_service.dart';
import 'package:sukh_app/services/connectivity_service.dart';
import 'package:sukh_app/services/shake_service.dart';
import 'package:sukh_app/services/theme_service.dart';
import 'package:sukh_app/services/update_service.dart';
import 'package:sukh_app/widgets/shake_hint_overlay.dart';
import 'package:sukh_app/widgets/snow_effect.dart';
import 'package:sukh_app/widgets/update_modal.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sukh_app/utils/restore_app_icon.dart';
import 'package:provider/provider.dart';
import 'package:sukh_app/utils/responsive_helper.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  await initializeDateFormatting('mn_MN', null);
  await NotificationService.initialize();

  await SessionService.checkAndHandleSession();

  await AppLogoNotifier.init();

  // Re-apply saved icon on startup (required for Android; iOS persists but we ensure consistency)
  await restoreAppIconOnStartup();

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
        // Check for app updates
        _checkForUpdate();
      }
    });
  }

  Future<void> _checkForUpdate() async {
    try {
      final versionInfo = await UpdateService.checkForUpdate();
      if (versionInfo != null && navigatorKey.currentContext != null) {
        // Wait a bit for the app to fully load
        await Future.delayed(const Duration(seconds: 2));
        if (navigatorKey.currentContext != null && mounted) {
          showDialog(
            context: navigatorKey.currentContext!,
            barrierDismissible: !versionInfo.isForceUpdate,
            builder: (context) => UpdateModal(versionInfo: versionInfo),
          );
        }
      }
    } catch (e) {
      print('Error checking for update: $e');
    }
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

      // Check for updates when app resumes
      _checkForUpdate();
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
      textTheme: const TextTheme(
        bodyMedium: TextStyle(
          fontWeight: FontWeight.w400,
          color: AppColors.lightTextPrimary,
          fontSize: 16,
        ),
        bodyLarge: TextStyle(
          color: AppColors.lightTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w400,
        ),
        bodySmall: TextStyle(
          color: AppColors.lightTextSecondary,
          fontSize: 14,
        ),
        titleLarge: TextStyle(
          color: AppColors.lightTextPrimary,
          fontSize: 26,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: AppColors.lightTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        titleSmall: TextStyle(
          color: AppColors.lightTextSecondary,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        labelLarge: TextStyle(
          color: AppColors.lightTextPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      iconTheme: const IconThemeData(color: AppColors.deepGreen, size: 24),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent, // Transparent to show gradient
        foregroundColor: AppColors.getDeepGreen(false), // false = light mode
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.getDeepGreen(false), // false = light mode
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightSurface,
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.lightBorderColor, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.lightInputGray),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.lightInputGray),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.deepGreen, width: 2),
        ),
        labelStyle: const TextStyle(
          color: AppColors.lightTextSecondary,
          fontSize: 14,
        ),
        hintStyle: const TextStyle(
          color: AppColors.lightTextSecondary,
          fontSize: 14,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.deepGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
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
      colorScheme: const ColorScheme.dark(
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
      textTheme: const TextTheme(
        bodyMedium: TextStyle(
          fontWeight: FontWeight.w400,
          color: AppColors.darkTextPrimary,
          fontSize: 16,
        ),
        bodyLarge: TextStyle(
          color: AppColors.darkTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w400,
        ),
        bodySmall: TextStyle(color: AppColors.darkTextSecondary, fontSize: 14),
        titleLarge: TextStyle(
          color: AppColors.darkTextPrimary,
          fontSize: 26,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: AppColors.darkTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        titleSmall: TextStyle(
          color: AppColors.darkTextSecondary,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        labelLarge: TextStyle(
          color: AppColors.darkTextPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      iconTheme: const IconThemeData(color: AppColors.darkTextPrimary, size: 24),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkBackground,
        foregroundColor: AppColors.getDeepGreen(true), // true = dark mode
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.getDeepGreen(true), // true = dark mode
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.darkBorderColor, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.darkInputGray),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.darkInputGray),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.deepGreen, width: 2),
        ),
        labelStyle: const TextStyle(
          color: AppColors.darkTextSecondary,
          fontSize: 14,
        ),
        hintStyle: const TextStyle(
          color: AppColors.darkTextSecondary,
          fontSize: 14,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.deepGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
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
          final mediaQuery = MediaQuery.of(context);
          final isTablet = mediaQuery.size.width >= 600;
          final designSize = isTablet
              ? const Size(768, 1024)
              : const Size(375, 812);

          return ScreenUtilInit(
            designSize: designSize,
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
                  child: MaterialApp.router(
                    debugShowCheckedModeBanner: false,
                    routerConfig: appRouter,
                    theme: _buildLightTheme(),
                    darkTheme: _buildDarkTheme(),
                    themeMode: themeService.themeMode,
                    builder: (context, child) {
                      Widget content = child ?? const SizedBox.shrink();

                      // Constrain and center layouts on tablet/iPad
                      if (ResponsiveHelper.isTablet(context)) {
                        content = Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: 650, // Standard premium width for tablet devices
                            ),
                            child: content,
                          ),
                        );
                      }

                      content = ShakeHintOverlay(
                        child: content,
                      );
                      if (_isDecember()) {
                        content = SnowEffect(child: content);
                      }
                      return content;
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
