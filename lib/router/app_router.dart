import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sukh_app/screens/burtguulekh/burtguulekh_neg.dart';
import 'package:sukh_app/screens/burtguulekh/burtguulekh_khoyor.dart';
import 'package:sukh_app/screens/medegdel/medegdel.dart';
import 'package:sukh_app/screens/newtrekhKhuudas.dart';
import 'package:sukh_app/screens/taniltsuulga/ehniih.dart';
import 'package:sukh_app/screens/Home/home.dart';
import 'package:sukh_app/screens/Tokhirhoo/tokhirgoo.dart';
import 'package:sukh_app/screens/GuilgeeniiTuukh/guilgeenii_tuukh.dart';
import 'package:sukh_app/screens/Nekhemjlekh/nekhemjlekh.dart';
import 'package:sukh_app/screens/sanal_khuselt/sanal_khuselt.dart';
import 'package:sukh_app/screens/duudlaga/duudlaga.dart';
import 'package:sukh_app/screens/mashin/mashin.dart';
import 'package:sukh_app/screens/burtguulekh/burtguulekh_guraw.dart';
import 'package:sukh_app/screens/nuutsUg/password_sergeekh.dart';
import 'package:sukh_app/services/storage_service.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  redirect: (context, state) async {
    final isLoggedIn = await StorageService.isLoggedIn();
    final taniltsuulgaKharakhEsekh = await StorageService.getTaniltsuulgaKharakhEsekh();
    final isGoingToLogin = state.matchedLocation == '/newtrekh' || state.matchedLocation == '/';
    final isGoingToRegister = state.matchedLocation.startsWith('/burtguulekh');
    final isGoingToOnboarding = state.matchedLocation == '/ekhniikh';
    final isGoingToPasswordReset = state.matchedLocation == '/nuutsUg';

    // If logged in and trying to access login/register pages
    if (isLoggedIn && (isGoingToLogin || isGoingToRegister)) {
      return '/nuur';
    }

    // If logged in and taniltsuulgaKharakhEsekh is false, redirect onboarding page to home
    if (isLoggedIn && !taniltsuulgaKharakhEsekh && isGoingToOnboarding) {
      return '/nuur';
    }

    // If not logged in and trying to access protected pages, redirect to login
    if (!isLoggedIn && !isGoingToLogin && !isGoingToRegister && !isGoingToOnboarding && !isGoingToPasswordReset) {
      return '/newtrekh';
    }

    // No redirect needed
    return null;
  },
  routes: [
    GoRoute(path: '/', builder: (context, state) => const Newtrekhkhuudas()),
    GoRoute(path: '/nuur', builder: (context, state) => const NuurKhuudas()),
    GoRoute(
      path: '/newtrekh',
      builder: (context, state) => const Newtrekhkhuudas(),
    ),
    GoRoute(
      path: '/nuutsUg',
      builder: (context, state) => const NuutsUgSergeekh(),
    ),
    GoRoute(path: '/ekhniikh', builder: (context, state) => OnboardingScreen()),
    GoRoute(
      path: '/burtguulekh_neg',
      builder: (context, state) => const Burtguulekh_Neg(),
    ),
    GoRoute(
      path: '/burtguulekh_khoyor',
      builder: (context, state) => Burtguulekh_Khoyor(
        locationData: state.extra as Map<String, dynamic>?,
      ),
    ),
    GoRoute(
      path: '/burtguulekh_guraw',
      builder: (context, state) => Burtguulekh_Guraw(
        locationData: state.extra as Map<String, dynamic>?,
      ),
    ),
    GoRoute(
      path: '/tokhirgoo',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const Tokhirgoo(),
        transitionDuration: const Duration(milliseconds: 350),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Slide from right to center with fade
          var slideAnimation = Tween<Offset>(
            begin: const Offset(1.0, 0.0), // Start from right side
            end: Offset.zero, // End at center
          ).animate(
            CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
          );

          var fadeAnimation = Tween<double>(
            begin: 0.0,
            end: 1.0,
          ).animate(
            CurvedAnimation(
              parent: animation,
              curve: Curves.easeIn,
            ),
          );

          return SlideTransition(
            position: slideAnimation,
            child: FadeTransition(
              opacity: fadeAnimation,
              child: child,
            ),
          );
        },
      ),
    ),
    GoRoute(
      path: '/guilgee',
      builder: (context, state) => const GuilgeeniiTuukh(),
    ),
    GoRoute(
      path: '/nekhemjlekh',
      builder: (context, state) => const NekhemjlekhPage(),
    ),
    GoRoute(
      path: '/sanal_khuselt',
      builder: (context, state) => const SanalKhuseltPage(),
    ),
    GoRoute(
      path: '/duudlaga',
      builder: (context, state) => const DuudlagaPage(),
    ),
    GoRoute(path: '/mashin', builder: (context, state) => const MashinPage()),
    GoRoute(
      path: '/medegdel',
      builder: (context, state) => const MedegdelPage(),
    ),
  ],
);
