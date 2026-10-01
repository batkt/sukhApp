import 'package:flutter/material.dart';
import 'package:sukh_app/services/connectivity_service.dart';

/// Интернэтгүй үед бүх дэлгэцийн дээд хэсэгт байнга харагдах мөр.
/// Холболт сэргэмэгц өөрөө алга болно.
class OfflineBanner extends StatelessWidget {
  final Widget child;
  const OfflineBanner({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        ValueListenableBuilder<bool>(
          valueListenable: ConnectivityService.online,
          builder: (context, online, _) {
            final top = MediaQuery.of(context).padding.top;
            return AnimatedPositioned(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              left: 12,
              right: 12,
              top: online ? -120 : top + 6,
              child: IgnorePointer(
                ignoring: online,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2B2F36),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.wifi_off_rounded, color: Color(0xFFFF8A80), size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Интернэт холболтгүй байна',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 1),
                              Text(
                                'Wi-Fi эсвэл мобайл датагаа асаана уу. Холболт сэргэмэгц мэдээлэл шинэчлэгдэнэ.',
                                style: TextStyle(color: Colors.white70, fontSize: 11.5, height: 1.3),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
