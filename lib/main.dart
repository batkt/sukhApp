import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'screens/newtrekhKhuudas.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(440, 956),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        // 👇 Wrap the entire MaterialApp with GestureDetector
        return GestureDetector(
          onTap: () {
            // This closes the keyboard when tapping outside a TextField
            FocusManager.instance.primaryFocus?.unfocus();
          },
          behavior: HitTestBehavior.translucent,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              textTheme: const TextTheme(
                bodyMedium: TextStyle(fontWeight: FontWeight.w400),
              ),
              fontFamily: 'Inter',
            ),
            home: const Newtrekhkhuudas(),
          ),
        );
      },
    );
  }
}
