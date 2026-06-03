import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:sukh_app/services/api_service.dart';
import 'package:sukh_app/services/storage_service.dart';
import 'package:sukh_app/constants/constants.dart';

class WebRTCPlayer extends StatefulWidget {
  final String rtspUrl;
  final String barilgiinId;
  final bool autoStart;
  final Duration? delay;

  const WebRTCPlayer({
    super.key,
    required this.rtspUrl,
    required this.barilgiinId,
    this.autoStart = false,
    this.delay,
  });

  @override
  State<WebRTCPlayer> createState() => _WebRTCPlayerState();
}

class _WebRTCPlayerState extends State<WebRTCPlayer> {
  static int _instanceCounter = 0;
  final int _instanceId = ++_instanceCounter;

  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  RTCPeerConnection? _peerConnection;
  bool _loading = true;
  String? _error;
  bool _isHandshaking = false;
  bool _started = false;
  Timer? _delayTimer;

  @override
  void initState() {
    super.initState();
    _started = widget.autoStart;
    if (_started) {
      if (widget.delay != null) {
        _delayTimer = Timer(widget.delay!, () {
          if (mounted) _initRenderer();
        });
      } else {
        _initRenderer();
      }
    }
  }

  void _startPlay() {
    if (_started) return;
    setState(() {
      _started = true;
    });
    _initRenderer();
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _stopEverything();
    super.dispose();
  }

  Future<void> _stopEverything() async {
    try {
      _localRenderer.srcObject = null;
      await _peerConnection?.close();
      await _peerConnection?.dispose();
      await _localRenderer.dispose();
    } catch (e) {
      debugPrint('Error cleaning up WebRTC resources: $e');
    }
  }

  Future<void> _initRenderer() async {
    try {
      await _localRenderer.initialize();
      _startHandshake();
    } catch (e) {
      if (mounted) setState(() => _error = 'Renderer error: $e');
    }
  }

  Future<void> _startHandshake() async {
    if (_isHandshaking) return;
    _isHandshaking = true;

    try {
      if (!mounted) return;
      setState(() {
        _loading = true;
        _error = null;
      });

      // 1. Create Peer Connection
      Map<String, dynamic> configuration = {
        "iceServers": [{"url": "stun:stun.l.google.com:19302"}],
        "sdpSemantics": "unified-plan",
        "iceCandidatePoolSize": 10,
      };

      _peerConnection = await createPeerConnection(configuration);

      _peerConnection!.onTrack = (RTCTrackEvent event) {
        if (event.track.kind == 'video' && event.streams.isNotEmpty) {
          if (mounted) {
            setState(() {
              _localRenderer.srcObject = event.streams[0];
              _loading = false;
            });
          }
        }
      };

      _peerConnection!.onConnectionState = (state) {
        if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
          if (mounted) setState(() => _loading = false);
        }
      };

      await _peerConnection!.addTransceiver(
        kind: RTCRtpMediaType.RTCRtpMediaTypeVideo,
        init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly),
      );

      RTCSessionDescription offer = await _peerConnection!.createOffer();
      await _peerConnection!.setLocalDescription(offer);

      int iceWait = 0;
      while (_peerConnection?.iceGatheringState != RTCIceGatheringState.RTCIceGatheringStateComplete && iceWait < 10) {
        await Future.delayed(const Duration(milliseconds: 100));
        iceWait++;
      }

      final finalOffer = await _peerConnection!.getLocalDescription();
      
      // 4. Send to Signaling Server
      final url = Uri.parse('${ApiService.baseUrl}/camera/stream/${widget.barilgiinId}/stream');
      
      // Get auth token
      final token = await StorageService.getToken();
      
      // Backend (cameraRoute.js) expects sdp64 (Base64) and rtsp or url
      final sdpBase64 = base64Encode(utf8.encode(finalOffer!.sdp!));
      
      final body = jsonEncode({
        'sdp64': sdpBase64,
        'rtsp': widget.rtspUrl,
        'url': widget.rtspUrl,
      });
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String? answerSdp;
        
        if (data['sdp64'] != null) {
          answerSdp = utf8.decode(base64Decode(data['sdp64']));
        } else if (data['sdp'] != null) {
          answerSdp = data['sdp'];
        }

        if (answerSdp != null) {
          await _peerConnection!.setRemoteDescription(
            RTCSessionDescription(answerSdp, 'answer'),
          );
        }
      } else {
        throw 'Server error: ${response.statusCode}';
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Холболт амжилтгүй: $e';
          _loading = false;
        });
      }
    } finally {
      _isHandshaking = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_started) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final isSmall = constraints.maxHeight < 150;
          return Container(
            color: const Color(0xFF0F172A),
            child: Center(
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: _startPlay,
                      child: Container(
                        padding: EdgeInsets.all(isSmall ? 8.w : 12.w),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.15),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 1.5),
                        ),
                        child: Icon(
                          Icons.play_arrow_rounded,
                          color: AppColors.primary,
                          size: isSmall ? 24.w : 32.w,
                        ),
                      ),
                    ),
                    SizedBox(height: isSmall ? 4.h : 8.h),
                    Text(
                      'Тоглуулах',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: isSmall ? 10.sp : 12.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }

    if (_error != null) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final isSmall = constraints.maxHeight < 150;
          return Container(
            color: const Color(0xFF0F172A),
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: _startHandshake,
                        child: Container(
                          padding: EdgeInsets.all(isSmall ? 8.w : 12.w),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.15),
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 1.5),
                          ),
                          child: Icon(
                            Icons.refresh_rounded,
                            color: AppColors.primary,
                            size: isSmall ? 24.w : 32.w,
                          ),
                        ),
                      ),
                      SizedBox(height: isSmall ? 4.h : 8.h),
                      GestureDetector(
                        onTap: _startHandshake,
                        child: Text(
                          'Дахин оролдох',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: isSmall ? 10.sp : 12.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    }

    return Stack(
      children: [
        RTCVideoView(
          _localRenderer,
          objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
        ),
        if (_loading)
          Container(
            color: Colors.black54,
            child: const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          ),
      ],
    );
  }
}
