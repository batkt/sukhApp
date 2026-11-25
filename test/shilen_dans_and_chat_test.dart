import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sukh_app/components/Home/animated_chat_preview_card.dart';
import 'package:sukh_app/widgets/skeleton_box.dart';

Widget _wrapWithScreenUtil(Widget child) {
  return ScreenUtilInit(
    designSize: const Size(390, 844),
    builder: (_, _) => MaterialApp(
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  testWidgets('AnimatedChatPreviewCard shows ШИНЭ badge and switches on swipe',
      (tester) async {
    var tapped = false;
    final chats = [
      {
        'ner': '112-р байр',
        'turul': 'barilga',
        'suuliinMessej': {
          'ilgeegchNer': 'Болд',
          'text': 'Сайн байна уу',
          'ognoo': DateTime.now().toIso8601String(),
        },
      },
      {
        'ner': 'Бүх байр',
        'turul': 'buh',
        'suuliinMessej': {
          'ilgeegchNer': 'СӨХ',
          'text': 'Хурал зарлагдлаа',
          'ognoo': DateTime.now().toIso8601String(),
        },
      },
    ];

    await tester.pumpWidget(
      _wrapWithScreenUtil(
        AnimatedChatPreviewCard(
          isDark: false,
          chats: chats,
          formatTime: (_) => '11:00',
          onTap: () => tapped = true,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('ШИНЭ'), findsOneWidget);
    expect(find.text('Чатлах'), findsOneWidget);
    expect(find.text('112-р байр'), findsOneWidget);
    expect(find.text('Сайн байна уу'), findsOneWidget);

    // Swipe left to switch to Бүх байр
    await tester.fling(
      find.byType(AnimatedChatPreviewCard),
      const Offset(-300, 0),
      1000,
    );
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Хурал зарлагдлаа'), findsOneWidget);

    await tester.tap(find.byType(AnimatedChatPreviewCard));
    expect(tapped, isTrue);
  });

  testWidgets('SkeletonBox renders cleanly', (tester) async {
    await tester.pumpWidget(
      _wrapWithScreenUtil(
        const SkeletonBox(width: 120, height: 24, borderRadius: 8),
      ),
    );
    await tester.pump();
    expect(find.byType(SkeletonBox), findsOneWidget);
  });
}
