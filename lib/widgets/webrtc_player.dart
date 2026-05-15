import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:http/http.dart' as http;
import 'package:sukh_app/services/api_service.dart';
import 'package:sukh_app/services/storage_service.dart';
import 'package:sukh_app/constants/constants.dart';

class WebRTCPlayer extends StatefulWidget {
  final String rtspUrl;
  final String barilgiinId;

  const WebRTCPlayer({
    super.key,
    required this.rtspUrl,
    required this.barilgiinId,
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

  @override
  void initState() {
    super.initState();
    debugPrint('🎬 [WebRTC Player #$_instanceId] Created for: ${widget.rtspUrl}');
    _initRenderer();
  }

  @override
  void dispose() {
    debugPrint('⚰️ [WebRTC Player #$_instanceId] Disposing...');
    _stopEverything();
    super.dispose();
  }

  Future<void> _stopEverything() async {
    _peerConnection?.dispose();
    _localRenderer.dispose();
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

    debugPrint('🚀 [WebRTC Player #$_instanceId] Starting handshake...');
    
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
          debugPrint('📹 [WebRTC Player #$_instanceId] Received Video Track');
          if (mounted) {
            setState(() {
              _localRenderer.srcObject = event.streams[0];
              _loading = false;
            });
          }
        }
      };

      _peerConnection!.onConnectionState = (state) {
        debugPrint('🌐 [WebRTC Player #$_instanceId] State: $state');
        if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
          if (mounted) setState(() => _loading = false);
        } else if (state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected || 
                   state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
          debugPrint('⚠️ [WebRTC Player #$_instanceId] Connection dropped: $state');
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
      
      debugPrint('📤 [WebRTC Player #$_instanceId] Signaling Request:');
      debugPrint('   URL: $url');
      debugPrint('   Payload: sdp64 length=${sdpBase64.length}, rtsp=${widget.rtspUrl}');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: body,
      );

      debugPrint('📥 [WebRTC Player #$_instanceId] Signaling Response: ${response.statusCode}');
      debugPrint('   Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String? answerSdp;
        
        if (data['sdp64'] != null) {
          answerSdp = utf8.decode(base64Decode(data['sdp64']));
        } else if (data['sdp'] != null) {
          answerSdp = data['sdp'];
        }

        if (answerSdp != null) {
          debugPrint('✅ [WebRTC Player #$_instanceId] Received Answer');
          await _peerConnection!.setRemoteDescription(
            RTCSessionDescription(answerSdp, 'answer'),
          );
        }
      } else {
        throw 'Server error: ${response.statusCode}';
      }
    } catch (e) {
      debugPrint('❌ [WebRTC Player #$_instanceId] Error: $e');
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
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 40),
            const SizedBox(height: 10),
            Text(_error!, style: const TextStyle(color: Colors.white70), textAlign: TextAlign.center),
            TextButton(onPressed: _startHandshake, child: const Text('Дахин оролдох', style: TextStyle(color: AppColors.primary))),
          ],
        ),
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
