import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'router/app_router.dart';
import 'package:sukh_app/services/notification_service.dart';
import 'package:sukh_app/services/session_service.dart';
import 'package:sukh_app/services/connectivity_service.dart';
import 'package:sukh_app/services/shake_service.dart';
import 'package:sukh_app/widgets/shake_hint_overlay.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await NotificationService.initialize();

  await SessionService.checkAndHandleSession();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final ConnectivityService _connectivityService = ConnectivityService();

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

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return GestureDetector(
          onTap: () {
            FocusManager.instance.primaryFocus?.unfocus();
          },
          behavior: HitTestBehavior.translucent,
          child: Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('lib/assets/img/background_image.png'),
                fit: BoxFit.none,
                scale: 3,
              ),
            ),
            child: MaterialApp.router(
              debugShowCheckedModeBanner: false,
              routerConfig: appRouter,
              theme: ThemeData(
                scaffoldBackgroundColor: Colors.transparent,
                textTheme: const TextTheme(
                  bodyMedium: TextStyle(fontWeight: FontWeight.w400),
                ),
                fontFamily: 'Inter',
              ),
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
  }
}
