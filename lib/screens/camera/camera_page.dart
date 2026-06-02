import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sukh_app/constants/constants.dart';
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

  const CameraConfig({
    required this.id,
    required this.name,
    required this.ip,
    this.port = 554,
    this.username = 'admin',
    this.password = 'Admin123',
    this.root = 'stream',
    this.enabled = true,
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
      );
}

// Default 16-channel Hikvision NVR sub-streams (H.264)
List<CameraConfig> _defaultCameras(String nvrIp) => List.generate(16, (i) {
      final ch = i + 1;
      return CameraConfig(
        id: 'cam-$ch',
        name: 'Камер $ch',
        ip: nvrIp,
        port: 554,
        username: 'admin',
        password: 'Admin123',
        root: 'Streaming/Channels/${ch}02',
      );
    });

const _prefsKey = 'sukh_camera_configs_v1';
const _nvrIpKey = 'sukh_nvr_ip';

// ─── Page ─────────────────────────────────────────────────────────────────────

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  List<CameraConfig> _cameras = [];
  String _nvrIp = '192.168.1.228';
  String _barilgiinId = '';
  bool _loading = true;
  int? _fullscreenIndex; // index in enabled list
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
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

    final prefs = await SharedPreferences.getInstance();
    final nvrIp = prefs.getString(_nvrIpKey) ?? '192.168.1.228';
    final saved = prefs.getString(_prefsKey);

    List<CameraConfig> cameras;
    if (saved != null) {
      try {
        final list = jsonDecode(saved) as List<dynamic>;
        cameras = list.map((e) => CameraConfig.fromJson(e as Map<String, dynamic>)).toList();
        // Migrate: ensure always 16 entries
        if (cameras.length != 16) cameras = _defaultCameras(nvrIp);
      } catch (_) {
        cameras = _defaultCameras(nvrIp);
      }
    } else {
      cameras = _defaultCameras(nvrIp);
    }

    if (mounted) {
      setState(() {
        _barilgiinId = barilgiinId;
        _nvrIp = nvrIp;
        _cameras = cameras;
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(_cameras.map((c) => c.toJson()).toList()));
    await prefs.setString(_nvrIpKey, _nvrIp);
  }

  void _updateCamera(CameraConfig updated) {
    setState(() {
      _cameras = _cameras.map((c) => c.id == updated.id ? updated : c).toList();
    });
    _save();
  }

  void _resetToDefaults() {
    setState(() {
      _cameras = _defaultCameras(_nvrIp);
    });
    _save();
  }

  List<CameraConfig> get _enabled => _cameras.where((c) => c.enabled).toList();

  @override
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
            icon: Icon(Icons.settings, color: isDark ? Colors.white70 : Colors.black87),
            onPressed: () => _openSettings(context),
            tooltip: 'Тохиргоо',
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
                            'Идэвхтэй камер байхгүй',
                            style: TextStyle(
                              fontSize: 16.sp,
                              color: isDark ? Colors.white70 : Colors.black87,
                              fontWeight: FontWeight.w600,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 24.h),
                          ElevatedButton(
                            onPressed: () => _openSettings(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 14.h),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                              elevation: 0,
                            ),
                            child: Text('Тохиргоо нээх', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  )
                : GridView.builder(
                    padding: EdgeInsets.all(6.w),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 16 / 9,
                      crossAxisSpacing: 4.w,
                      mainAxisSpacing: 4.h,
                    ),
                    itemCount: _enabled.length,
                    itemBuilder: (ctx, i) => _CameraCard(
                      camera: _enabled[i],
                      barilgiinId: _barilgiinId,
                      onFullscreen: () => setState(() => _fullscreenIndex = i),
                    ),
                  ),
      ),
    );
  }

  void _openSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SettingsSheet(
        cameras: _cameras,
        nvrIp: _nvrIp,
        onNvrIpChanged: (ip) {
          setState(() => _nvrIp = ip);
          _save();
        },
        onCameraToggled: (id, enabled) {
          final cam = _cameras.firstWhere((c) => c.id == id);
          _updateCamera(cam.copyWith(enabled: enabled));
        },
        onReset: _resetToDefaults,
      ),
    );
  }
}

// ─── Camera Card ──────────────────────────────────────────────────────────────

class _CameraCard extends StatelessWidget {
  final CameraConfig camera;
  final String barilgiinId;
  final VoidCallback onFullscreen;

  const _CameraCard({
    required this.camera,
    required this.barilgiinId,
    required this.onFullscreen,
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
                child: Text(
                  camera.name,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w600,
                  ),
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
  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Settings Sheet ───────────────────────────────────────────────────────────

class _SettingsSheet extends StatefulWidget {
  final List<CameraConfig> cameras;
  final String nvrIp;
  final ValueChanged<String> onNvrIpChanged;
  final void Function(String id, bool enabled) onCameraToggled;
  final VoidCallback onReset;

  const _SettingsSheet({
    required this.cameras,
    required this.nvrIp,
    required this.onNvrIpChanged,
    required this.onCameraToggled,
    required this.onReset,
  });

  @override
  State<_SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<_SettingsSheet> {
  late TextEditingController _ipCtrl;

  @override
  void initState() {
    super.initState();
    _ipCtrl = TextEditingController(text: widget.nvrIp);
  }

  @override
  void dispose() {
    _ipCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Column(
          children: [
            // Handle
            Center(
              child: Container(
                margin: EdgeInsets.only(top: 10.h, bottom: 8.h),
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            // Header
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
              child: Row(
                children: [
                  Text(
                    'Камер тохиргоо',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      widget.onReset();
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Анхдагч',
                      style: TextStyle(color: AppColors.primary, fontSize: 12.sp),
                    ),
                  ),
                ],
              ),
            ),
            // NVR IP input
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: Row(
                children: [
                  Text(
                    'NVR IP:',
                    style: TextStyle(color: Colors.white70, fontSize: 12.sp),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: TextField(
                      controller: _ipCtrl,
                      style: TextStyle(color: Colors.white, fontSize: 13.sp, fontFamily: 'monospace'),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white10,
                        contentPadding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                          borderSide: BorderSide.none,
                        ),
                        hintText: '192.168.1.228',
                        hintStyle: const TextStyle(color: Colors.white24),
                      ),
                      onSubmitted: widget.onNvrIpChanged,
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: Colors.white10, height: 1.h),
            // Camera list
            Expanded(
              child: ListView.builder(
                controller: controller,
                itemCount: widget.cameras.length,
                itemBuilder: (_, i) {
                  final cam = widget.cameras[i];
                  return ListTile(
                    dense: true,
                    leading: Icon(
                      Icons.videocam,
                      color: cam.enabled ? AppColors.primary : Colors.white24,
                      size: 20.sp,
                    ),
                    title: Text(
                      cam.name,
                      style: TextStyle(
                        color: cam.enabled ? Colors.white : Colors.white38,
                        fontSize: 13.sp,
                      ),
                    ),
                    subtitle: Text(
                      cam.root,
                      style: TextStyle(color: Colors.white24, fontSize: 10.sp, fontFamily: 'monospace'),
                    ),
                    trailing: Switch(
                      value: cam.enabled,
                      onChanged: (v) {
                        setState(() {});
                        widget.onCameraToggled(cam.id, v);
                      },
                      activeColor: AppColors.primary,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
