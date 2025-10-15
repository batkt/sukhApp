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
import 'package:sukh_app/screens/newtrekhKhuudas.dart';

final GoRouter appRouter = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const Newtrekhkhuudas()),
    GoRoute(path: '/nuur', builder: (context, state) => const NuurKhuudas()),
    GoRoute(
      path: '/newtrekh',
      builder: (context, state) => const Newtrekhkhuudas(),
    ),
    GoRoute(path: '/ekhniikh', builder: (context, state) => OnboardingScreen()),
    GoRoute(
      path: '/burtguulekh_neg',
      builder: (context, state) => const Burtguulekh_Neg(),
    ),
    GoRoute(
      path: '/burtguulekh_khoyor',
      builder: (context, state) => const Burtguulekh_Khoyor(),
    ),
    GoRoute(path: '/tokhirgoo', builder: (context, state) => const Tokhirgoo()),
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
