import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/services/api_service.dart';
import 'package:sukh_app/services/storage_service.dart';
import 'package:sukh_app/widgets/webrtc_player.dart';
import 'package:sukh_app/widgets/standard_app_bar.dart' show buildStandardAppBar;

// ─── Model ────────────────────────────────────────────────────────────────────

class CameraConfig {
  final String id;
  final String name;
  final String ip;
  final int port;
  final String username;
  final String password;
  final String root;
  final bool enabled;
  final bool isMain;

  const CameraConfig({
    required this.id,
    required this.name,
    required this.ip,
    this.port = 554,
    this.username = 'admin',
    this.password = 'Admin123',
    this.root = 'stream',
    this.enabled = true,
    this.isMain = false,
  });

  String get rtspUrl =>
      'rtsp://${Uri.encodeComponent(username)}:${Uri.encodeComponent(password)}@$ip:$port/$root';

  CameraConfig copyWith({
    String? name,
    String? ip,
    int? port,
    String? username,
    String? password,
    String? root,
    bool? enabled,
    bool? isMain,
  }) =>
      CameraConfig(
        id: id,
        name: name ?? this.name,
        ip: ip ?? this.ip,
        port: port ?? this.port,
        username: username ?? this.username,
        password: password ?? this.password,
        root: root ?? this.root,
        enabled: enabled ?? this.enabled,
        isMain: isMain ?? this.isMain,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'ip': ip,
        'port': port,
        'username': username,
        'password': password,
        'root': root,
        'enabled': enabled,
        'isMain': isMain,
      };

  factory CameraConfig.fromJson(Map<String, dynamic> j) => CameraConfig(
        id: j['id']?.toString() ?? '',
        name: j['name']?.toString() ?? '',
        ip: j['ip']?.toString() ?? '',
        port: (j['port'] as num?)?.toInt() ?? 554,
        username: j['username']?.toString() ?? 'admin',
        password: j['password']?.toString() ?? 'Admin123',
        root: j['root']?.toString() ?? 'stream',
        enabled: j['enabled'] as bool? ?? true,
        isMain: j['isMain'] as bool? ?? false,
      );
}



// ─── Page ─────────────────────────────────────────────────────────────────────

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  List<CameraConfig> _cameras = [];
  String _barilgiinId = '';
  bool _loading = true;
  int? _fullscreenIndex; // index in enabled list
  String? _errorMessage;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() { _loading = true; _errorMessage = null; });

    final barilgiinId = await StorageService.getBarilgiinId() ?? '';
    final baigId = await StorageService.getBaiguullagiinId();
    final isNonOrg = baigId == null ||
        baigId == 'null' ||
        baigId.isEmpty ||
        baigId == '698e7fd3b6dd386b6c56a808';

    if (isNonOrg || barilgiinId.isEmpty) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Тухайн СӨХ нь камерийн холболт хийгээгүй байна.';
          _loading = false;
        });
      }
      return;
    }

    try {
      final camMaps = await ApiService.fetchBuildingCameras(
        baiguullagiinId: baigId!,
        barilgiinId: barilgiinId,
      );

      final cameras = camMaps.map((c) => CameraConfig.fromJson(c)).toList();

      if (mounted) {
        setState(() {
          _barilgiinId = barilgiinId;
          _cameras = cameras;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Камерын мэдээлэл татахад алдаа гарлаа.';
          _loading = false;
        });
      }
    }
  }

  List<CameraConfig> get _enabled {
    final list = _cameras.where((c) => c.enabled).toList();
    list.sort((a, b) {
      if (a.isMain && !b.isMain) return -1;
      if (!a.isMain && b.isMain) return 1;
      return 0;
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.darkBackground : Colors.white,
        appBar: buildStandardAppBar(
          context,
          title: 'Камерууд',
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [AppColors.darkBackground, AppColors.darkBackground.withOpacity(0.9)]
                  : [Colors.white, const Color(0xFFF5F9F7), const Color(0xFFE8F4F0)],
            ),
          ),
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(30.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF97316).withOpacity(isDark ? 0.2 : 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.videocam_rounded,
                      size: 64.w,
                      color: const Color(0xFFF97316),
                    ),
                  ),
                  SizedBox(height: 24.h),
                  Text(
                    _errorMessage!,
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: isDark ? Colors.white70 : Colors.black87,
                      fontWeight: FontWeight.w600,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                 
                 
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (_fullscreenIndex != null) {
      return _FullscreenView(
        camera: _enabled[_fullscreenIndex!],
        barilgiinId: _barilgiinId,
        onClose: () => setState(() => _fullscreenIndex = null),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : Colors.white,
      appBar: buildStandardAppBar(
        context,
        title: 'Камерууд',
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: isDark ? Colors.white70 : Colors.black87),
            onPressed: _load,
            tooltip: 'Шинэчлэх',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [AppColors.darkBackground, AppColors.darkBackground.withOpacity(0.9)]
                : [Colors.white, const Color(0xFFF5F9F7), const Color(0xFFE8F4F0)],
          ),
        ),
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : _enabled.isEmpty
                ? Center(
                    child: Padding(
                      padding: EdgeInsets.all(30.w),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: EdgeInsets.all(20.w),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF97316).withOpacity(isDark ? 0.2 : 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.videocam_off_rounded,
                              size: 64.w,
                              color: const Color(0xFFF97316),
                            ),
                          ),
                          SizedBox(height: 24.h),
                          Text(
                            'Баазанас камер байхгүй',
                            style: TextStyle(
                              fontSize: 16.sp,
                              color: isDark ? Colors.white70 : Colors.black87,
                              fontWeight: FontWeight.w600,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'Тохиргоо → Камерийн тохиргоо рүү орж камеруудаа бүртгэнэ үү',
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: isDark ? Colors.white38 : Colors.black54,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 24.h),
                          ElevatedButton.icon(
                            onPressed: _load,
                            icon: Icon(Icons.refresh_rounded, size: 18.sp),
                            label: Text('Шинэчлэх', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 14.h),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                              elevation: 0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : Builder(
                    builder: (context) {
                      int totalPages = (_enabled.length / 6).ceil();
                      if (totalPages == 0) totalPages = 1;
                      if (_currentPage >= totalPages) {
                        _currentPage = totalPages - 1;
                      }
                      if (_currentPage < 0) {
                        _currentPage = 0;
                      }

                      final startIndex = _currentPage * 6;
                      final endIndex = (startIndex + 6) < _enabled.length ? (startIndex + 6) : _enabled.length;
                      final pageCameras = _enabled.sublist(startIndex, endIndex);

                      return Column(
                        children: [
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, gridConstraints) {
                                final gridHeight = gridConstraints.maxHeight;
                                final gridWidth = gridConstraints.maxWidth;
                                
                                const rowsCount = 3;
                                final spacingH = 4.h;
                                final paddingH = 12.h; // top + bottom padding of GridView
                                final availableHeight = gridHeight - paddingH - ((rowsCount - 1) * spacingH);
                                
                                final cardHeight = availableHeight / rowsCount;
                                final cardWidth = (gridWidth - 4.w) / 2;
                                final childAspectRatio = cardWidth / cardHeight;

                                return GridView.builder(
                                  physics: const NeverScrollableScrollPhysics(), // No need to scroll since they fit exactly
                                  cacheExtent: 0.0, // Strictly render only visible cards to optimize memory and data usage
                                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 6.h),
                                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    childAspectRatio: childAspectRatio,
                                    crossAxisSpacing: 4.w,
                                    mainAxisSpacing: spacingH,
                                  ),
                                  itemCount: pageCameras.length,
                                  itemBuilder: (ctx, i) {
                                    final absoluteIndex = startIndex + i;
                                    return _CameraCard(
                                      camera: pageCameras[i],
                                      barilgiinId: _barilgiinId,
                                      delay: Duration(milliseconds: i * 300), // Stagger WebRTC signaling handshakes to avoid worker timeouts
                                      onFullscreen: () => setState(() => _fullscreenIndex = absoluteIndex),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                          _buildPagination(totalPages),
                        ],
                      );
                    },
                  ),
      ),
    );
  }

  Widget _buildPagination(int totalPages) {
    if (totalPages <= 1) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white70 : Colors.black87;

    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: isDark ? Colors.black26 : Colors.black.withOpacity(0.03),
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white10 : Colors.black12,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.chevron_left_rounded, size: 24.sp),
            color: textColor,
            disabledColor: isDark ? Colors.white24 : Colors.black26,
            onPressed: _currentPage > 0
                ? () => setState(() => _currentPage--)
                : null,
            style: IconButton.styleFrom(
              backgroundColor: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
            ),
          ),
          Text(
            '${_currentPage + 1} / $totalPages',
            style: TextStyle(
              color: textColor,
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: Icon(Icons.chevron_right_rounded, size: 24.sp),
            color: textColor,
            disabledColor: isDark ? Colors.white24 : Colors.black26,
            onPressed: _currentPage < totalPages - 1
                ? () => setState(() => _currentPage++)
                : null,
            style: IconButton.styleFrom(
              backgroundColor: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
            ),
          ),
        ],
      ),
    );
  }

}

// ─── Camera Card ──────────────────────────────────────────────────────────────

class _CameraCard extends StatelessWidget {
  final CameraConfig camera;
  final String barilgiinId;
  final VoidCallback onFullscreen;
  final Duration? delay;

  const _CameraCard({
    required this.camera,
    required this.barilgiinId,
    required this.onFullscreen,
    this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onFullscreen,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          border: Border.all(color: Colors.white10),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            WebRTCPlayer(
              key: ValueKey('cam_${camera.id}'),
              rtspUrl: camera.rtspUrl,
              barilgiinId: barilgiinId,
              autoStart: true,
              delay: delay,
            ),
            // Name label
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black87, Colors.transparent],
                  ),
                ),
                child: Row(
                  children: [
                    if (camera.isMain) ...[
                      Icon(Icons.star_rounded, color: Colors.amber, size: 10.sp),
                      SizedBox(width: 2.w),
                    ],
                    Expanded(
                      child: Text(
                        camera.name,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Fullscreen hint icon
            Positioned(
              top: 4.h,
              right: 4.w,
              child: Icon(Icons.fullscreen, color: Colors.white38, size: 14.sp),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Fullscreen View ──────────────────────────────────────────────────────────

class _FullscreenView extends StatefulWidget {
  final CameraConfig camera;
  final String barilgiinId;
  final VoidCallback onClose;

  const _FullscreenView({
    required this.camera,
    required this.barilgiinId,
    required this.onClose,
  });

  @override
  State<_FullscreenView> createState() => _FullscreenViewState();
}

class _FullscreenViewState extends State<_FullscreenView> {
  bool _isLandscape = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }

  void _toggleRotation() {
    setState(() {
      _isLandscape = !_isLandscape;
      if (_isLandscape) {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      } else {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
        ]);
      }
    });
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          WebRTCPlayer(
            key: ValueKey('fs_${widget.camera.id}'),
            rtspUrl: widget.camera.rtspUrl,
            barilgiinId: widget.barilgiinId,
            autoStart: true,
          ),
          // Top bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black87, Colors.transparent],
                ),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: widget.onClose,
                    child: Icon(Icons.fullscreen_exit, color: Colors.white, size: 24.sp),
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    widget.camera.name,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _toggleRotation,
                    child: Icon(
                      Icons.screen_rotation_rounded,
                      color: Colors.white,
                      size: 24.sp,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
