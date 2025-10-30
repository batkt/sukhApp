import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'router/app_router.dart';
import 'package:sukh_app/services/notification_service.dart';
import 'package:sukh_app/services/session_service.dart';

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
    return LayoutBuilder(
      builder: (context, constraints) {
        return ScreenUtilInit(
          designSize: Size(
            MediaQueryData.fromView(
              WidgetsBinding.instance.platformDispatcher.views.first,
            ).size.width,
            MediaQueryData.fromView(
              WidgetsBinding.instance.platformDispatcher.views.first,
            ).size.height,
          ),
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
                ),
              ),
            );
          },
        );
      },
    );
  }
}
