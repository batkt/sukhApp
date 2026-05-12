import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/services/api_service.dart';
import 'package:sukh_app/services/storage_service.dart';
import 'package:sukh_app/services/socket_service.dart';
import 'package:sukh_app/widgets/standard_app_bar.dart';
import 'package:sukh_app/widgets/glass_snackbar.dart';
import 'package:sukh_app/utils/theme_extensions.dart';
import 'package:sukh_app/widgets/hls_player.dart';
import 'package:sukh_app/widgets/webrtc_player.dart';

class ParkingGate {
  final String name;
  final String type; 
  final List<ParkingCamera> cameras;

  ParkingGate({
    required this.name,
    required this.type,
    required this.cameras,
  });

  factory ParkingGate.fromJson(Map<String, dynamic> json) {
    var cameraList = (json['camera'] as List? ?? [])
        .map((c) => ParkingCamera.fromJson(c))
        .toList();
    return ParkingGate(
      name: json['ner'] ?? 'Хаалга',
      type: json['turul'] ?? 'Мэдэгдэхгүй',
      cameras: cameraList,
    );
  }
}

class ParkingCamera {
  final String ip;
  final String name;
  final Map<String, dynamic> config;

  ParkingCamera({
    required this.ip,
    required this.name,
    required this.config,
  });

  factory ParkingCamera.fromJson(Map<String, dynamic> json) {
    return ParkingCamera(
      ip: json['cameraIP'] ?? '',
      name: json['cameraName'] ?? 'Камер',
      config: json['tokhirgoo'] ?? {},
    );
  }
}

class ParkingSite {
  final String id;
  final String name;
  final String? barilgiinId;
  final List<ParkingGate> gates;

  ParkingSite({
    required this.id,
    required this.name,
    this.barilgiinId,
    required this.gates,
  });

  factory ParkingSite.fromJson(Map<String, dynamic> json) {
    var gateList = (json['khaalga'] as List? ?? [])
        .map((g) => ParkingGate.fromJson(g))
        .toList();
    return ParkingSite(
      id: json['_id'] ?? '',
      name: json['ner'] ?? 'ParkEase',
      barilgiinId: json['barilgiinId']?.toString(),
      gates: gateList,
    );
  }
}

class ParkEasePage extends StatefulWidget {
  const ParkEasePage({super.key});

  @override
  State<ParkEasePage> createState() => _ParkEasePageState();
}

class _ParkEasePageState extends State<ParkEasePage> {
  bool _isLoading = false; 
  List<ParkingSite> _sites = [];
  String? _errorMessage;
  String? _baiguullagiinId;
  
  final Map<String, bool> _openingGates = {};
  final Map<String, Map<String, dynamic>> _lastRecognitions = {};
  final Map<String, Map<String, dynamic>> _pendingPayments = {};
  final Map<String, bool> _isProcessingPayment = {};
  Map<String, dynamic>? _overallLatestRecognition;
  String? _expandedCameraIP;

  bool _isSocketConnected = false;
  late final StreamSubscription _socketStatusSub;
  Timer? _pollingTimer;
  Timer? _tickTimer;

  @override
  void initState() {
    super.initState();
    debugPrint('🚀 [ParkEase] initState called');
    _initData();
    
    // Track socket connection status
    _socketStatusSub = Stream.periodic(const Duration(seconds: 2)).listen((_) {
      final connected = SocketService.instance.isConnected;
      if (connected != _isSocketConnected) {
        setState(() => _isSocketConnected = connected);
      }
    });

    // Poll for latest plate every 5 seconds
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _fetchLatestEntry();
    });

    // Tick every second to update the elapsed time counter
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_overallLatestRecognition != null && mounted) {
        setState(() {}); // Trigger rebuild to recalculate elapsed time
      }
    });
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    _pollingTimer?.cancel();
    _socketStatusSub.cancel();
    _cleanupSockets();
    super.dispose();
  }
  
  Future<void> _initData() async {
    try {
      _baiguullagiinId = await StorageService.getBaiguullagiinId();
    } catch (_) {}
    await _loadSettings();
    _setupSockets();
    await _fetchLatestEntry();
  }

  /// Fetch the latest plate via REST API (polls every 5s for real-time updates)
  Future<void> _fetchLatestEntry() async {
    try {
      final entry = await ApiService.fetchLatestParkingEntry();
      if (entry != null && mounted) {
        final plate = entry['mashiniiDugaar']?.toString();
        // Get the most recent history entry for timestamp
        final tuukh = entry['tuukh'] as List? ?? [];
        final latestHistory = tuukh.isNotEmpty ? tuukh.last : null;
        final tsagiinTuukh = latestHistory?['tsagiinTuukh'] as List? ?? [];
        final orsonTsag = tsagiinTuukh.isNotEmpty ? tsagiinTuukh.last['orsonTsag'] : entry['createdAt'];
        
        DateTime timestamp = DateTime.now();
        if (orsonTsag != null) {
          try { timestamp = DateTime.parse(orsonTsag.toString()); } catch (_) {}
        }

        // Only update if it's a new/different plate entry
        final currentPlate = _overallLatestRecognition?['mashiniiDugaar'];
        final currentId = _overallLatestRecognition?['_id'];
        
        final cameraIP = latestHistory?['orsonKhaalga']?.toString() ?? '';
        final entryId = entry['_id']?.toString();
        
        if (plate != null && plate.isNotEmpty && (plate != currentPlate || entryId != currentId)) {
          debugPrint('📋 [ParkEase] New plate from REST: $plate (was: $currentPlate)');
          
          // Find barilgiinId for this camera
          String? barilgiinId;
          for (var site in _sites) {
            for (var gate in site.gates) {
              if (gate.cameras.any((c) => c.ip == cameraIP)) {
                barilgiinId = site.barilgiinId ?? site.id;
                break;
              }
            }
          }

          setState(() {
            final data = {
              'mashiniiDugaar': plate,
              'cameraIP': cameraIP,
              'timestamp': timestamp,
              '_id': entryId,
              'barilgiinId': barilgiinId,
            };
            _overallLatestRecognition = data;
            if (cameraIP.isNotEmpty) {
              _lastRecognitions[cameraIP] = data;
            }
          });
        }
      }
    } catch (e) {
      // Silent fail for polling — don't spam logs
    }
  }


  void _setupSockets() {
    if (_baiguullagiinId == null) return;
    final socket = SocketService.instance;
    debugPrint('🔌 [ParkEase] Setting up sockets for Org: $_baiguullagiinId');

    // 1. General listener for all organization parking events
    socket.listenForZogsoolUpdates(_baiguullagiinId!, (data) {
      debugPrint('📩 [ParkEase] Received Global Socket Data: $data');
      final cameraIP = data['cameraIP']?.toString();
      if (cameraIP != null) {
        _handleRecognition(cameraIP, data);
      }
    });

    // 2. Specific listeners for each camera
    for (var site in _sites) {
      for (var gate in site.gates) {
        for (var camera in gate.cameras) {
          if (camera.ip.isEmpty) continue;
          final type = gate.type.toLowerCase();
          
          if (type.contains('орох') || type.contains('entry') || type.contains('in')) {
            debugPrint('📡 [ParkEase] Listening for Entry at ${camera.ip}');
            socket.listenForZogsoolOroh(_baiguullagiinId!, camera.ip, (data) {
              debugPrint('📥 [ParkEase] Entry Detected: $data');
              _handleRecognition(camera.ip, data);
            });
          } else if (type.contains('гарах') || type.contains('exit') || type.contains('out')) {
            debugPrint('📡 [ParkEase] Listening for Exit at ${camera.ip}');
            socket.listenForZogsoolGarah(_baiguullagiinId!, camera.ip, (data) {
              debugPrint('📥 [ParkEase] Exit Detected: $data');
              _handleRecognition(camera.ip, data);
            });
          } else {
            debugPrint('⚠️ [ParkEase] Unknown gate type: ${gate.type}. Listening for both.');
            socket.listenForZogsoolOroh(_baiguullagiinId!, camera.ip, (data) => _handleRecognition(camera.ip, data));
            socket.listenForZogsoolGarah(_baiguullagiinId!, camera.ip, (data) => _handleRecognition(camera.ip, data));
          }
        }
      }
    }
  }

  void _cleanupSockets() {
    debugPrint('🔌 [ParkEase] Cleaning up sockets');
    // Implementation for specific cleanup if needed
  }

  void _handleRecognition(String cameraIP, Map<String, dynamic> data) {
    if (!mounted) return;
    debugPrint('🎯 [ParkEase] Handling Recognition for $cameraIP: $data');
    
    // Try to get entry time from data, fallback to now
    DateTime timestamp = DateTime.now();
    final orsonTsag = data['tuukh']?[0]?['tsagiinTuukh']?[0]?['orsonTsag'] ?? data['orsonTsag'];
    if (orsonTsag != null) {
      try { timestamp = DateTime.parse(orsonTsag.toString()); } catch (_) {}
    }

    // Find the barilgiinId for this camera
    String? barilgiinId;
    for (var site in _sites) {
      for (var gate in site.gates) {
        if (gate.cameras.any((c) => c.ip == cameraIP)) {
          barilgiinId = site.barilgiinId ?? site.id;
          break;
        }
      }
    }

    setState(() {
      final entry = { ...data, 'timestamp': timestamp, 'cameraIP': cameraIP, 'barilgiinId': barilgiinId };
      _lastRecognitions[cameraIP] = entry;
      _overallLatestRecognition = entry;
    });
    _fetchPaymentInfo(cameraIP, data['mashiniiDugaar']);
  }

  Future<void> _fetchPaymentInfo(String cameraIP, String? plateNumber) async {
    if (plateNumber == null || plateNumber.isEmpty) return;
    try {
      final response = await ApiService.fetchParkingPaymentInfo(plateNumber);
      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        if (mounted) {
          setState(() {
            _pendingPayments[cameraIP] = { ...(data as Map<String, dynamic>) };
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _loadSettings() async {
    debugPrint('🔄 [ParkEase] _loadSettings started');
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final response = await ApiService.fetchParkingSettings();
      debugPrint('📩 [ParkEase] API Response: $response');
      final List<dynamic> list = response['jagsaalt'] ?? [];
      if (list.isNotEmpty) {
        _sites = list
            .map((s) => ParkingSite.fromJson(s))
            .where((s) => s.gates.isNotEmpty)
            .toList();
        debugPrint('✅ [ParkEase] Loaded ${_sites.length} sites (filtered)');
      } else {
        debugPrint('⚠️ [ParkEase] API returned empty list');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'ParkEase мэдээлэл авахад алдаа гарлаа';
        });
      }
      debugPrint('❌ [ParkEase] LoadSettings Error: $e');
    } finally {
      if (mounted) {
        if (_sites.isEmpty && _errorMessage == null) {
          _errorMessage = 'ParkEase мэдээлэл олдсонгүй';
        }

        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openGate(String ip, {String? barilgiinId}) async {
    if (_openingGates[ip] == true) return;
    setState(() => _openingGates[ip] = true);
    try {
      final success = await ApiService.openParkingGate(ip, barilgiinId: barilgiinId);
      if (mounted) {
        if (success) {
          showGlassSnackBar(context, message: 'Хаалт нээх команд илгээгдлээ', icon: Icons.check_circle, iconColor: Colors.green);
        } else {
          showGlassSnackBar(context, message: 'Алдаа гарлаа', icon: Icons.error, iconColor: Colors.red);
        }
      }
    } finally {
      if (mounted) setState(() => _openingGates[ip] = false);
    }
  }

  Future<void> _handlePaymentAction(String cameraIP, bool toInvoice) async {
    final payment = _pendingPayments[cameraIP];
    if (payment == null) return;
    setState(() => _isProcessingPayment[cameraIP] = true);
    try {
      bool success = false;
      if (toInvoice) {
        success = await ApiService.addParkingFeeToInvoice(
          plateNumber: payment['plate_number'] ?? '',
          amount: (payment['amount'] ?? 0).toDouble(), 
          sessionId: payment['session_id'] ?? '',
          parkingId: payment['parking_id'] ?? '',
        );
      } else {
        success = await ApiService.payParkingFeeDirectly(
          plateNumber: payment['plate_number'] ?? '',
          amount: (payment['amount'] ?? 0).toDouble(),
          sessionId: payment['session_id'] ?? '',
          parkingId: payment['parking_id'] ?? '',
        );
      }
      if (mounted) {
        if (success) {
          showGlassSnackBar(context, message: toInvoice ? 'Нэхэмжлэх дээр нэмэгдлээ' : 'Төлбөр амжилттай', icon: Icons.check_circle, iconColor: Colors.green);
          setState(() { _pendingPayments.remove(cameraIP); });
        } else {
          showGlassSnackBar(context, message: 'Алдаа гарлаа', icon: Icons.error, iconColor: Colors.red);
        }
      }
    } finally {
      if (mounted) setState(() => _isProcessingPayment[cameraIP] = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : Colors.white,
      appBar: buildStandardAppBar(
        context,
        title: 'ParkEase',
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [AppColors.darkBackground, AppColors.darkBackground.withOpacity(0.9)]
                : [Colors.white, Color(0xFFF5F9F7), Color(0xFFE8F4F0)],
          ),
        ),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _sites.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_errorMessage != null && _sites.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(30.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_off_rounded, size: 64.w, color: Colors.grey.withOpacity(0.5)),
              SizedBox(height: 20.h),
              Text(
                _errorMessage!,
                style: TextStyle(fontSize: 16.sp, color: Colors.grey[600], fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 30.h),
              ElevatedButton(
                onPressed: _loadSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 14.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                ),
                child: Text('Дахин оролдох', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      );
    }

    if (_sites.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.layers_clear_outlined, size: 80.w, color: Colors.grey.withOpacity(0.2)),
            SizedBox(height: 16.h),
            Text(
              'Мэдээлэл олдсонгүй',
              style: TextStyle(fontSize: 16.sp, color: Colors.grey, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSettings,
      color: AppColors.primary,
      child: ListView.builder(
        padding: EdgeInsets.fromLTRB(18.w, 15.h, 18.w, 30.h),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _sites.length + (_overallLatestRecognition != null ? 1 : 0),
        itemBuilder: (context, index) {
          if (_overallLatestRecognition != null) {
            if (index == 0) return _buildLatestRecognitionBanner();
            index--;
          }
          final site = _sites[index];
          return _buildSiteCard(site);
        },
      ),
    );
  }

  Widget _buildLatestRecognitionBanner() {
    final recognition = _overallLatestRecognition!;
    final entryTime = (recognition['timestamp'] as DateTime?) ?? DateTime.now();
    final now = DateTime.now();
    final diff = now.isAfter(entryTime) ? now.difference(entryTime) : Duration.zero;
    
    final hours = diff.inHours.toString().padLeft(2, '0');
    final minutes = (diff.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (diff.inSeconds % 60).toString().padLeft(2, '0');

    return Container(
      margin: EdgeInsets.only(bottom: 20.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 24.w),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Сүүлд танигдсан',
                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11.sp, fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 2.h),
                Text(
                  recognition['mashiniiDugaar'] ?? '---',
                  style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(width: 10.w),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Орсон: ${DateFormat('HH:mm').format(entryTime)}',
                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 9.sp),
              ),
              SizedBox(height: 4.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  '$hours : $minutes : $seconds',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSiteCard(ParkingSite site) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: EdgeInsets.only(bottom: 20.h),
      decoration: BoxDecoration(
        color: AppColors.getSurface(isDark),
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(20.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    site.name,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _isSocketConnected ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isSocketConnected ? Colors.green : Colors.red,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _isSocketConnected ? Colors.green : Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isSocketConnected ? 'ONLINE' : 'OFFLINE',
                        style: TextStyle(
                          color: _isSocketConnected ? Colors.green : Colors.red,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: site.gates.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final gate = site.gates[index];
              return _buildGateItem(gate, site);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGateItem(ParkingGate gate, ParkingSite site) {
    final primaryCamera = gate.cameras.isNotEmpty ? gate.cameras[0] : null;
    final cameraIP = primaryCamera?.ip;
    final isOpening = cameraIP != null && (_openingGates[cameraIP] ?? false);
    
    final recognition = cameraIP != null ? _lastRecognitions[cameraIP] : null;
    final pendingPayment = cameraIP != null ? _pendingPayments[cameraIP] : null;

    final isExpanded = cameraIP != null && _expandedCameraIP == cameraIP;
    final effectiveBarilgiinId = site.barilgiinId ?? site.id;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 15.h),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  if (cameraIP != null) {
                    setState(() { _expandedCameraIP = isExpanded ? null : cameraIP; });
                  }
                },
                child: Container(
                  width: 44.w, height: 44.w,
                  decoration: BoxDecoration(
                    color: isExpanded ? AppColors.primary.withOpacity(0.12) : Colors.grey.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isExpanded ? Icons.videocam_off_rounded : Icons.videocam_rounded,
                    size: 22.w, color: isExpanded ? AppColors.primary : Colors.grey,
                  ),
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(gate.name, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600)),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Text(gate.type, style: TextStyle(fontSize: 12.sp, color: Colors.grey[600])),
                        if (recognition != null) ...[
                          SizedBox(width: 10.w),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                            decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(6.r)),
                            child: Text(recognition['mashiniiDugaar'] ?? '', style: TextStyle(fontSize: 11.sp, color: Colors.green, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (cameraIP != null)
                ElevatedButton(
                  onPressed: isOpening ? null : () => _openGate(cameraIP, barilgiinId: recognition?['barilgiinId'] ?? effectiveBarilgiinId),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                    elevation: 0, padding: EdgeInsets.symmetric(horizontal: 18.w),
                    minimumSize: Size(85.w, 40.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                  ),
                  child: isOpening ? SizedBox(width: 18.w, height: 18.w, child: const CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation<Color>(Colors.white))) : Text('Нээх', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        ),
        if (pendingPayment != null && cameraIP != null) _buildPaymentCard(cameraIP, pendingPayment),
        if (isExpanded && primaryCamera != null) _buildCameraStream(primaryCamera, recognition),
      ],
    );
  }

  Widget _buildPaymentCard(String cameraIP, Map<String, dynamic> payment) {
    final bool isProcessing = _isProcessingPayment[cameraIP] ?? false;
    return Container(
      margin: EdgeInsets.fromLTRB(18.w, 0, 18.w, 15.h),
      padding: EdgeInsets.all(15.w),
      decoration: BoxDecoration(color: Colors.red.withOpacity(0.06), borderRadius: BorderRadius.circular(15.r), border: Border.all(color: Colors.red.withOpacity(0.12))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.payment_rounded, size: 18.w, color: Colors.red),
              SizedBox(width: 10.w),
              Text('Төлбөрийн мэдээлэл', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold, color: Colors.red)),
              const Spacer(),
              Text('${NumberFormat('#,###').format(payment['amount'] ?? 0)} ₮', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold, color: Colors.red)),
            ],
          ),
          SizedBox(height: 15.h),
          Row(
            children: [
              Expanded(child: _buildActionBtn('Нэхэмжлэх дээр нэмэх', Icons.receipt_long_rounded, Colors.blue, isProcessing ? null : () => _handlePaymentAction(cameraIP, true))),
              SizedBox(width: 10.w),
              Expanded(child: _buildActionBtn('Шууд төлөх', Icons.account_balance_wallet_rounded, Colors.green, isProcessing ? null : () => _handlePaymentAction(cameraIP, false))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionBtn(String label, IconData icon, Color color, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 10.w),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10.r), border: Border.all(color: color.withOpacity(0.3))),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16.w, color: color),
            SizedBox(width: 8.w),
            Flexible(child: Text(label, style: TextStyle(fontSize: 11.sp, color: color, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraStream(ParkingCamera camera, Map<String, dynamic>? recognition) {
    return Container(
      width: double.infinity,
      height: 220.h,
      margin: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(15.r),
        border: Border.all(color: AppColors.primary.withOpacity(0.4)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15.r),
        child: _sites.isEmpty ? const SizedBox() : Builder(
          builder: (context) {
            // Construct the RTSP URL
            final tokhirgoo = camera.config;
            final user = tokhirgoo['USER'] ?? '';
            final pass = tokhirgoo['PASSWD'] ?? '';
            final port = tokhirgoo['PORT'] ?? '554';
            final root = tokhirgoo['ROOT'] ?? 'stream';
            final ip = camera.ip;

            // rtsp://user:pass@ip:port/root
            final rtspUrl = 'rtsp://$user:$pass@$ip:$port/$root';
            
            // Find the site ID for this camera (needed for signaling room)
            String barilgiinId = '';
            for (var site in _sites) {
              for (var gate in site.gates) {
                if (gate.cameras.any((c) => c.ip == ip)) {
                  // Prioritize barilgiinId over site.id for local worker registration
                  barilgiinId = site.barilgiinId ?? site.id;
                  break;
                }
              }
            }

            return WebRTCPlayer(
              rtspUrl: rtspUrl,
              barilgiinId: barilgiinId,
            );
          },
        ),
      ),
    );
  }
}
