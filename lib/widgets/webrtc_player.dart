import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:http/http.dart' as http;
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
  RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  RTCPeerConnection? _peerConnection;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initRenderer();
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _peerConnection?.dispose();
    super.dispose();
  }

  Future<void> _initRenderer() async {
    await _localRenderer.initialize();
    _startHandshake();
  }

  Future<void> _startHandshake() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      // 1. Create Peer Connection
      Map<String, dynamic> configuration = {
        "iceServers": [
          {"url": "stun:stun.l.google.com:19302"},
          {"url": "stun:stun1.l.google.com:19302"},
          {"url": "stun:stun2.l.google.com:19302"},
          {"url": "stun:stun3.l.google.com:19302"},
          {"url": "stun:stun4.l.google.com:19302"},
          {"url": "stun:stun.stunprotocol.org:3478"},
        ],
        "sdpSemantics": "unified-plan"
      };

      _peerConnection = await createPeerConnection(configuration);

      // Add dummy audio/video transceiver to get an offer
      await _peerConnection!.addTransceiver(
        kind: RTCRtpMediaType.RTCRtpMediaTypeVideo,
        init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly),
      );

      // 2. Create Offer
      RTCSessionDescription offer = await _peerConnection!.createOffer();
      await _peerConnection!.setLocalDescription(offer);

      // Wait for ICE gathering to complete (or timeout)
      // On 5G/Mobile data, this can take a few seconds
      int iceWaitCount = 0;
      while (_peerConnection!.iceGatheringState != RTCIceGatheringState.RTCIceGatheringStateComplete && iceWaitCount < 50) {
        await Future.delayed(const Duration(milliseconds: 100));
        iceWaitCount++;
      }
      
      if (_peerConnection!.iceGatheringState != RTCIceGatheringState.RTCIceGatheringStateComplete) {
        debugPrint('⚠️ [WebRTC] ICE gathering timed out (State: ${_peerConnection!.iceGatheringState})');
      }
      
      // Get the updated offer with gathered candidates
      offer = await _peerConnection!.getLocalDescription() ?? offer;

      // 3. Send to VPS Signaling Bridge
      final vpsUrl = 'https://amarhome.mn/api/camera/stream/${widget.barilgiinId}/stream';
      
      debugPrint('📤 [WebRTC] Sending Offer to VPS (SDP length: ${offer.sdp?.length}, ICE state: ${_peerConnection!.iceGatheringState})');
      final response = await http.post(
        Uri.parse(vpsUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'url': widget.rtspUrl,
          'rtsp': widget.rtspUrl, // Some backends expect 'rtsp'
          'sdp': offer.sdp,      // Raw SDP
          'sdp64': base64Encode(utf8.encode(offer.sdp!)), // Base64 SDP
        }),
      );

      if (response.statusCode != 200) {
        debugPrint('❌ [WebRTC] Signaling Failed (${response.statusCode}): ${response.body}');
        throw Exception('Сигнал дамжуулахад алдаа гарлаа: ${response.statusCode}');
      }

      // Set up listeners BEFORE setting remote description
      _peerConnection!.onTrack = (RTCTrackEvent event) {
        debugPrint('📹 [WebRTC] onTrack: ${event.track.kind}');
        if (event.track.kind == 'video' && event.streams.isNotEmpty) {
          if (mounted) {
            setState(() {
              _localRenderer.srcObject = event.streams[0];
              _loading = false;
            });
          }
        }
      };

      _peerConnection!.onAddStream = (MediaStream stream) {
        debugPrint('📹 [WebRTC] onAddStream: ${stream.id}');
        if (mounted) {
          setState(() {
            _localRenderer.srcObject = stream;
            _loading = false;
          });
        }
      };

      _peerConnection!.onConnectionState = (state) {
        debugPrint('🌐 [WebRTC] Connection State Changed: $state');
        if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
          if (mounted && _loading) {
            setState(() => _loading = false);
          }
        } else if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
          if (mounted) {
            setState(() {
              _error = 'Холболт амжилтгүй (NAT Traversal Failed). Гар утасны дата ашиглаж байгаа бол STUN/TURN алдаа гарсан байж болзошгүй.';
              _loading = false;
            });
          }
        }
      };

      // 4. Set Remote Description (Answer)
      String rawAnswer = response.body;
      if (rawAnswer.isNotEmpty) {
        debugPrint('📹 [WebRTC] Received SDP Answer (Raw): ${rawAnswer.substring(0, rawAnswer.length > 100 ? 100 : rawAnswer.length)}...');
      } else {
        debugPrint('⚠️ [WebRTC] Received empty response body');
      }
      
      String sdpAnswer = rawAnswer;
      try {
        final data = jsonDecode(rawAnswer);
        if (data is Map) {
          sdpAnswer = data['sdp'] ?? data['sdp64'] ?? data['sdpAnswer'] ?? rawAnswer;
          if (data['sdp64'] != null && sdpAnswer == data['sdp64']) {
            sdpAnswer = utf8.decode(base64.decode(sdpAnswer));
          }
        }
      } catch (_) {}

      if (sdpAnswer.isEmpty) {
        throw Exception('Server returned empty SDP answer');
      }

      RTCSessionDescription answer = RTCSessionDescription(sdpAnswer, 'answer');
      await _peerConnection!.setRemoteDescription(answer);

    } catch (e) {
      debugPrint('❌ [WebRTC] Handshake Error: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Stack(
        alignment: Alignment.center,
        children: [
          RTCVideoView(
            _localRenderer,
            objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
            mirror: false,
          ),
          if (_loading)
            const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.white70, strokeWidth: 2),
                  SizedBox(height: 12),
                  Text(
                    'Камер холбогдож байна...',
                    style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          if (_error != null)
            Container(
              color: Colors.black87,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.videocam_off_rounded, color: Colors.white38, size: 42),
                    const SizedBox(height: 12),
                    Text(
                      'Холболтын алдаа',
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _startHandshake,
                      icon: const Icon(Icons.refresh_rounded, size: 18, color: Colors.white),
                      label: const Text('Дахин оролдох', style: TextStyle(color: Colors.white, fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ),
          // Live indicator
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: (!_loading && _error == null) ? Colors.red : Colors.grey,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle, color: Colors.white, size: 8),
                  SizedBox(width: 4),
                  Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
