import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sukh_app/services/version_service.dart';

class CommonAppFooter extends StatefulWidget {
  final bool isDark;
  const CommonAppFooter({super.key, required this.isDark});

  @override
  State<CommonAppFooter> createState() => _CommonAppFooterState();
}

class _CommonAppFooterState extends State<CommonAppFooter> {
  String _version = '...';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final v = await VersionService.getAppVersion();
    if (mounted) {
      setState(() {
        _version = v;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '© 2026 Powered by Zevtabs LLC',
          style: TextStyle(
            fontSize: 10.sp,
            color: widget.isDark
                ? Colors.white.withOpacity(0.25)
                : Colors.black.withOpacity(0.3),
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          'Version $_version',
          style: TextStyle(
            fontSize: 9.sp,
            color: widget.isDark
                ? Colors.white.withOpacity(0.2)
                : Colors.black.withOpacity(0.25),
          ),
        ),
      ],
    );
  }
}
