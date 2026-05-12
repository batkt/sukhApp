import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:http/http.dart' as http;

/// WHEP (WebRTC-HTTP Egress Protocol) player for near-zero latency camera streams.
/// Connects to MediaMTX's WHEP endpoint for sub-second latency.
class HlsPlayer extends StatefulWidget {
  final String url; // HLS URL — we derive the WHEP URL from it
  final String? title;

  const HlsPlayer({
    super.key,
    required this.url,
    this.title,
  });

  @override
  State<HlsPlayer> createState() => _HlsPlayerState();
}

class _HlsPlayerState extends State<HlsPlayer> with AutomaticKeepAliveClientMixin {
  RTCVideoRenderer _renderer = RTCVideoRenderer();
  RTCPeerConnection? _pc;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  String? _whepResourceUrl; // For teardown

  @override
  bool get wantKeepAlive => true;

  /// Derive the WHEP URL from the HLS URL
  /// e.g. http://103.236.194.99:8888/live/camera1/index.m3u8
  ///   -> http://103.236.194.99:8889/live/camera1/whep
  String _getWhepUrl() {
    final uri = Uri.parse(widget.url);
    // Replace port 8888 with 8889, strip the m3u8 file, add /whep
    final pathSegments = uri.pathSegments.toList();
    // Remove 'index.m3u8' or similar file from end
    if (pathSegments.isNotEmpty && pathSegments.last.contains('.m3u8')) {
      pathSegments.removeLast();
    }
    final newPath = '/${pathSegments.join('/')}/whep';
    return uri.replace(port: 8889, path: newPath).toString();
  }

  @override
  void initState() {
    super.initState();
    _initRenderer();
  }

  Future<void> _initRenderer() async {
    await _renderer.initialize();
    _connect();
  }

  Future<void> _connect() async {
    final whepUrl = _getWhepUrl();
    debugPrint('🎬 [WHEP] Connecting to: $whepUrl');

    try {
      // Create peer connection
      final config = <String, dynamic>{
        'iceServers': [
          {'urls': 'stun:stun.l.google.com:19302'},
        ],
        'sdpSemantics': 'unified-plan',
      };

      _pc = await createPeerConnection(config);

      // Add receive-only transceivers for video and audio
      await _pc!.addTransceiver(
        kind: RTCRtpMediaType.RTCRtpMediaTypeVideo,
        init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly),
      );
      await _pc!.addTransceiver(
        kind: RTCRtpMediaType.RTCRtpMediaTypeAudio,
        init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly),
      );

      // Handle incoming streams
      _pc!.onTrack = (RTCTrackEvent event) {
        debugPrint('📹 [WHEP] Track received: ${event.track.kind}');
        if (event.track.kind == 'video' && event.streams.isNotEmpty) {
          if (mounted) {
            setState(() {
              _renderer.srcObject = event.streams[0];
              _isLoading = false;
              _hasError = false;
            });
          }
        }
      };

      _pc!.onConnectionState = (RTCPeerConnectionState state) {
        debugPrint('🔗 [WHEP] Connection state: $state');
        if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
            state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
          if (mounted) {
            setState(() {
              _hasError = true;
              _errorMessage = 'Холболт тасарлаа';
            });
          }
        }
      };

      // Create SDP offer
      final offer = await _pc!.createOffer();
      await _pc!.setLocalDescription(offer);

      // Wait for ICE gathering to complete (or timeout)
      await _waitForIceGathering();

      // Get the final local description with ICE candidates
      final localDesc = await _pc!.getLocalDescription();
      if (localDesc == null) {
        throw Exception('No local description');
      }

      // Send SDP offer to WHEP endpoint
      debugPrint('📤 [WHEP] Sending offer to $whepUrl');
      final response = await http.post(
        Uri.parse(whepUrl),
        headers: {
          'Content-Type': 'application/sdp',
        },
        body: localDesc.sdp,
      );

      debugPrint('📥 [WHEP] Response status: ${response.statusCode}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        // Store the resource URL for teardown
        _whepResourceUrl = response.headers['location'];

        // Set remote SDP answer
        final answer = RTCSessionDescription(response.body, 'answer');
        await _pc!.setRemoteDescription(answer);
        debugPrint('✅ [WHEP] Connected! Sub-second latency active.');
      } else {
        throw Exception('WHEP server returned ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ [WHEP] Error: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
          _errorMessage = 'Камертай холбогдож чадсангүй';
        });
      }
    }
  }

  Future<void> _waitForIceGathering() async {
    if (_pc == null) return;
    
    // Check if already complete
    if (_pc!.iceGatheringState == RTCIceGatheringState.RTCIceGatheringStateComplete) {
      return;
    }

    // Wait up to 3 seconds for ICE gathering
    final completer = Future.delayed(const Duration(seconds: 3));
    bool done = false;
    
    _pc!.onIceGatheringState = (RTCIceGatheringState state) {
      if (state == RTCIceGatheringState.RTCIceGatheringStateComplete) {
        done = true;
      }
    };

    // Poll until done or timeout
    final deadline = DateTime.now().add(const Duration(seconds: 3));
    while (!done && DateTime.now().isBefore(deadline)) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (_pc?.iceGatheringState == RTCIceGatheringState.RTCIceGatheringStateComplete) {
        break;
      }
    }
  }

  Future<void> _disconnect() async {
    // WHEP teardown
    if (_whepResourceUrl != null) {
      try {
        await http.delete(Uri.parse(_whepResourceUrl!));
      } catch (_) {}
    }
    
    _renderer.srcObject = null;
    await _pc?.close();
    _pc = null;
  }

  @override
  void dispose() {
    _disconnect();
    _renderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Container(
      color: Colors.black,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (!_hasError)
            RTCVideoView(
              _renderer,
              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
              mirror: false,
            ),
          if (_isLoading && !_hasError)
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
          if (_hasError)
            Container(
              color: Colors.black87,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.videocam_off_rounded, color: Colors.white38, size: 42),
                    const SizedBox(height: 12),
                    Text(
                      _errorMessage ?? 'Алдаа гарлаа',
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _hasError = false;
                          _isLoading = true;
                        });
                        _disconnect().then((_) => _connect());
                      },
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
                color: (!_isLoading && !_hasError) ? Colors.red : Colors.grey,
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
          if (widget.title != null)
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white10),
                ),
                child: Text(
                  widget.title!,
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
