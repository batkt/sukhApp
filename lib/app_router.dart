import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sukh_app/screens/burtguulekh/burtguulekh_neg.dart';
import 'package:sukh_app/screens/burtguulekh/burtguulekh_khoyor.dart';
import 'package:sukh_app/screens/newtrekhKhuudas.dart';
import 'package:sukh_app/screens/taniltsuulga/ehniih.dart';
import 'package:sukh_app/screens/Home/home.dart';
import 'package:sukh_app/screens/Tokhirhoo/tokhirgoo.dart';
import 'package:sukh_app/screens/GuilgeeniiTuukh/guilgeenii_tuukh.dart';

final GoRouter appRouter = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const BookingScreen()),
    GoRoute(
      path: '/burtguulekh_neg',
      builder: (context, state) => const Burtguulekh_Neg(),
    ),
    GoRoute(
      path: '/burtguulekh_khoyor',
      builder: (context, state) => const Burtguulekh_Khoyor(),
    ),
    GoRoute(path: '/ekhniikh', builder: (context, state) => OnboardingScreen()),
    GoRoute(path: '/tokhirgoo', builder: (context, state) => const Tokhirgoo()),
    GoRoute(
      path: '/guilgee',
      builder: (context, state) => const GuilgeeniiTuukh(),
    ),
  ],
);
