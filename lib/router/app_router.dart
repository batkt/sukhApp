import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sukh_app/screens/burtguulekh/burtguulekh_neg.dart';
import 'package:sukh_app/screens/burtguulekh/burtguulekh_khoyor.dart';
import 'package:sukh_app/screens/medegdel/medegdel.dart';
import 'package:sukh_app/screens/newtrekh/newtrekhKhuudas.dart';
import 'package:sukh_app/screens/taniltsuulga/ehniih.dart';
import 'package:sukh_app/screens/Home/home.dart';
import 'package:sukh_app/screens/Tokhirhoo/tokhirgoo.dart';
import 'package:sukh_app/screens/geree/geree.dart';
import 'package:sukh_app/screens/nekhemjlekh/nekhemjlekh.dart';
import 'package:sukh_app/screens/sanal_khuselt/sanal_khuselt.dart';
import 'package:sukh_app/screens/duudlaga/duudlaga.dart';
import 'package:sukh_app/screens/mashin/mashin.dart';
import 'package:sukh_app/screens/burtguulekh/burtguulekh_guraw.dart';
import 'package:sukh_app/screens/nuutsUg/password_sergeekh.dart';
import 'package:sukh_app/services/storage_service.dart';

// Custom fade transition helper function
CustomTransitionPage<void> buildFadeTransition({
  required LocalKey key,
  required Widget child,
  int durationMs = 200,
}) {
  return CustomTransitionPage(
    key: key,
    child: child,
    transitionDuration: Duration(milliseconds: durationMs),
    reverseTransitionDuration: Duration(milliseconds: durationMs),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      // Fade out the old page
      final fadeOut = Tween<double>(begin: 1.0, end: 0.0).animate(
        CurvedAnimation(
          parent: secondaryAnimation,
          curve: Curves.easeInOut,
        ),
      );

      // Fade in the new page
      final fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOut,
        ),
      );

      return FadeTransition(
        opacity: animation.status == AnimationStatus.reverse ? fadeOut : fadeIn,
        child: child,
      );
    },
  );
}

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  redirect: (context, state) async {
    final isLoggedIn = await StorageService.isLoggedIn();
    final taniltsuulgaKharakhEsekh =
        await StorageService.getTaniltsuulgaKharakhEsekh();
    final isGoingToLogin =
        state.matchedLocation == '/newtrekh' || state.matchedLocation == '/';
    final isGoingToRegister = state.matchedLocation.startsWith('/burtguulekh');
    final isGoingToOnboarding = state.matchedLocation == '/ekhniikh';
    final isGoingToPasswordReset = state.matchedLocation == '/nuutsUg';

    if (isLoggedIn && (isGoingToLogin || isGoingToRegister)) {
      return '/nuur';
    }

    if (isLoggedIn && !taniltsuulgaKharakhEsekh && isGoingToOnboarding) {
      return '/nuur';
    }

    if (!isLoggedIn &&
        !isGoingToLogin &&
        !isGoingToRegister &&
        !isGoingToOnboarding &&
        !isGoingToPasswordReset) {
      return '/newtrekh';
    }

    // No redirect needed
    return null;
  },
  routes: [
    GoRoute(
      path: '/',
      pageBuilder: (context, state) => buildFadeTransition(
        key: state.pageKey,
        child: const Newtrekhkhuudas(),
      ),
    ),
    GoRoute(
      path: '/nuur',
      pageBuilder: (context, state) => buildFadeTransition(
        key: state.pageKey,
        child: NuurKhuudas(key: UniqueKey()),
      ),
    ),
    GoRoute(
      path: '/newtrekh',
      pageBuilder: (context, state) => buildFadeTransition(
        key: state.pageKey,
        child: const Newtrekhkhuudas(),
      ),
    ),
    GoRoute(
      path: '/nuutsUg',
      pageBuilder: (context, state) => buildFadeTransition(
        key: state.pageKey,
        child: const NuutsUgSergeekh(),
      ),
    ),
    GoRoute(
      path: '/ekhniikh',
      pageBuilder: (context, state) => buildFadeTransition(
        key: state.pageKey,
        child: OnboardingScreen(),
      ),
    ),
    GoRoute(
      path: '/burtguulekh_neg',
      pageBuilder: (context, state) => buildFadeTransition(
        key: state.pageKey,
        child: const Burtguulekh_Neg(),
      ),
    ),
    GoRoute(
      path: '/burtguulekh_khoyor',
      pageBuilder: (context, state) => buildFadeTransition(
        key: state.pageKey,
        child: Burtguulekh_Khoyor(
          locationData: state.extra as Map<String, dynamic>?,
        ),
      ),
    ),
    GoRoute(
      path: '/burtguulekh_guraw',
      pageBuilder: (context, state) => buildFadeTransition(
        key: state.pageKey,
        child: Burtguulekh_Guraw(locationData: state.extra as Map<String, dynamic>?),
      ),
    ),
    GoRoute(
      path: '/tokhirgoo',
      pageBuilder: (context, state) => buildFadeTransition(
        key: state.pageKey,
        child: const Tokhirgoo(),
      ),
    ),
    GoRoute(
      path: '/geree',
      pageBuilder: (context, state) => buildFadeTransition(
        key: state.pageKey,
        child: const Geree(),
      ),
    ),
    GoRoute(
      path: '/nekhemjlekh',
      pageBuilder: (context, state) => buildFadeTransition(
        key: state.pageKey,
        child: const NekhemjlekhPage(),
      ),
    ),
    GoRoute(
      path: '/sanal_khuselt',
      pageBuilder: (context, state) => buildFadeTransition(
        key: state.pageKey,
        child: const SanalKhuseltPage(),
      ),
    ),
    GoRoute(
      path: '/duudlaga',
      pageBuilder: (context, state) => buildFadeTransition(
        key: state.pageKey,
        child: const DuudlagaPage(),
      ),
    ),
    GoRoute(
      path: '/mashin',
      pageBuilder: (context, state) => buildFadeTransition(
        key: state.pageKey,
        child: const MashinPage(),
      ),
    ),
    GoRoute(
      path: '/medegdel',
      pageBuilder: (context, state) => buildFadeTransition(
        key: state.pageKey,
        child: const MedegdelPage(),
      ),
    ),
  ],
);
