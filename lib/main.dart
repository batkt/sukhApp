import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'router/app_router.dart';
import 'package:sukh_app/services/notification_service.dart';
import 'package:sukh_app/services/session_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notification service
  await NotificationService.initialize();

  // Check session on app startup
  await SessionService.checkAndHandleSession();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Check session when app comes to foreground
    if (state == AppLifecycleState.resumed) {
      SessionService.checkAndHandleSession().then((isValid) {
        if (!isValid && mounted) {
          appRouter.refresh();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(440, 956),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return GestureDetector(
          onTap: () {
            FocusManager.instance.primaryFocus?.unfocus();
          },
          behavior: HitTestBehavior.translucent,
          child: MaterialApp.router(
            debugShowCheckedModeBanner: false,
            routerConfig: appRouter,
            theme: ThemeData(
              scaffoldBackgroundColor: Colors.black,
              textTheme: const TextTheme(
                bodyMedium: TextStyle(fontWeight: FontWeight.w400),
              ),
              fontFamily: 'Inter',
            ),
          ),
        );
      },
    );
  }
}
