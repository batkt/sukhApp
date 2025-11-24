import 'package:flutter/material.dart';

/// Shake hint overlay - modal is now shown after login
/// This widget just wraps the child, modal is triggered from login screen
class ShakeHintOverlay extends StatelessWidget {
  final Widget child;

  const ShakeHintOverlay({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
