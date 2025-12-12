import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/widgets/glass_snackbar.dart';
import 'package:go_router/go_router.dart';
import 'package:sukh_app/services/api_service.dart';
import 'package:sukh_app/services/storage_service.dart';
import 'package:sukh_app/services/socket_service.dart';
import 'package:sukh_app/widgets/app_logo.dart';
import 'package:sukh_app/widgets/shake_hint_modal.dart';
import 'package:sukh_app/main.dart' show navigatorKey;

class AppBackground extends StatelessWidget {
  final Widget child;
  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(child: child);
  }
}

class Newtrekhkhuudas extends StatefulWidget {
  const Newtrekhkhuudas({super.key});

  @override
  State<Newtrekhkhuudas> createState() => _NewtrekhkhuudasState();
}

class _NewtrekhkhuudasState extends State<Newtrekhkhuudas> {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  bool _isLoading = false;
  bool _showEmailField = false;

  @override
  void initState() {
    super.initState();
    phoneController.addListener(() => setState(() {}));
    emailController.addListener(() => setState(() {}));
    _loadSavedPhoneNumber();
  }

  Future<void> _loadSavedPhoneNumber() async {
    final savedPhone = await StorageService.getSavedPhoneNumber();
    if (savedPhone != null && mounted) {
      setState(() {
        phoneController.text = savedPhone;
      });
    }
  }

  Future<void> _showModalAfterNavigation() async {
    // Wait for navigation to complete (page transition is 300ms)
    await Future.delayed(const Duration(milliseconds: 1000));

    // Try multiple times with increasing delays to ensure context is ready
    for (int i = 0; i < 10; i++) {
      await Future.delayed(Duration(milliseconds: 200 * (i + 1)));

      final navigatorContext = navigatorKey.currentContext;
      if (navigatorContext != null && navigatorContext.mounted) {
        try {
          // Show the modal - it will check storage internally
          showShakeHintModal(navigatorContext);
          return; // Successfully showed modal, exit
        } catch (e) {
          // Continue trying if there's an error
          continue;
        }
      }
    }
  }

  @override
  void dispose() {
    phoneController.dispose();
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isTablet = ScreenUtil().screenWidth > 700;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: AppBackground(
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isTablet ? 300.w : double.infinity,
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 28.w,
                            vertical: 12.h,
                          ),
                          child: Column(
                            children: [
                              const Spacer(),
                              const AppLogo(),
                              SizedBox(height: 12.h),
                              Text(
                                'Тавтай морил',
                                style: TextStyle(
                                  color: AppColors.grayColor,
                                  fontSize: 22.sp,
                                ),
                              ),
                              SizedBox(height: 24.h),
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16.r),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.15),
                                      offset: const Offset(0, 4),
                                      blurRadius: 12,
                                      spreadRadius: 0,
                                    ),
                                  ],
                                ),
                                child: TextFormField(
                                  controller: phoneController,
                                  keyboardType: TextInputType.phone,
                                  autofocus: false,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.5,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Утасны дугаар',
                                    hintStyle: TextStyle(
                                      color: Colors.white.withOpacity(0.5),
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w400,
                                    ),
                                    filled: true,
                                    fillColor: AppColors.inputGrayColor
                                        .withOpacity(0.3),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 20.w,
                                      vertical: 16.h,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16.r),
                                      borderSide: BorderSide(
                                        color: Colors.white.withOpacity(0.1),
                                        width: 1.5,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16.r),
                                      borderSide: BorderSide(
                                        color: AppColors.grayColor.withOpacity(
                                          0.8,
                                        ),
                                        width: 2,
                                      ),
                                    ),
                                    suffixIcon: phoneController.text.isNotEmpty
                                        ? IconButton(
                                            icon: Icon(
                                              Icons.clear_rounded,
                                              color: Colors.white.withOpacity(
                                                0.7,
                                              ),
                                              size: 20.sp,
                                            ),
                                            onPressed: () =>
                                                phoneController.clear(),
                                          )
                                        : null,
                                  ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(8),
                                  ],
                                ),
                              ),
                              SizedBox(height: 12.h),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8.w),
                                child: Text(
                                  _showEmailField
                                      ? 'Хэтэвчний системд бүртгэлгүй байна. Имэйл хаягаа оруулна уу'
                                      : 'Хэтэвчний системд бүртгэлтэй утасны дугаараа оруулна уу',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppColors.grayColor.withOpacity(0.7),
                                    fontSize: 12.sp,
                                  ),
                                ),
                              ),
                              if (_showEmailField) ...[
                                SizedBox(height: 12.h),
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16.r),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.15),
                                        offset: const Offset(0, 4),
                                        blurRadius: 12,
                                        spreadRadius: 0,
                                      ),
                                    ],
                                  ),
                                  child: TextFormField(
                                    controller: emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 0.2,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'Имэйл хаяг',
                                      hintStyle: TextStyle(
                                        color: Colors.white.withOpacity(0.5),
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w400,
                                      ),
                                      filled: true,
                                      fillColor: AppColors.inputGrayColor
                                          .withOpacity(0.3),
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 20.w,
                                        vertical: 16.h,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          16.r,
                                        ),
                                        borderSide: BorderSide(
                                          color: Colors.white.withOpacity(0.1),
                                          width: 1.5,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          16.r,
                                        ),
                                        borderSide: BorderSide(
                                          color: AppColors.grayColor
                                              .withOpacity(0.8),
                                          width: 2,
                                        ),
                                      ),
                                      suffixIcon:
                                          emailController.text.isNotEmpty
                                          ? IconButton(
                                              icon: Icon(
                                                Icons.clear_rounded,
                                                color: Colors.white.withOpacity(
                                                  0.7,
                                                ),
                                                size: 20.sp,
                                              ),
                                              onPressed: () =>
                                                  emailController.clear(),
                                            )
                                          : null,
                                    ),
                                  ),
                                ),
                              ],
                              SizedBox(height: 24.h),
                              GestureDetector(
                                onTap: _isLoading
                                    ? null
                                    : () async {
                                        String inputPhone = phoneController.text
                                            .trim();

                                        if (inputPhone.isEmpty) {
                                          showGlassSnackBar(
                                            context,
                                            message: "Утасны дугаар оруулна уу",
                                            icon: Icons.error,
                                            iconColor: Colors.red,
                                          );
                                          return;
                                        } else if (!RegExp(
                                          r'^\d+$',
                                        ).hasMatch(inputPhone)) {
                                          showGlassSnackBar(
                                            context,
                                            message: "Зөвхөн тоо оруулна уу!",
                                            icon: Icons.error,
                                            iconColor: Colors.red,
                                          );
                                          return;
                                        }

                                        setState(() {
                                          _isLoading = true;
                                        });

                                        try {
                                          // If email field is shown, user needs to register first
                                          if (_showEmailField) {
                                            final inputEmail = emailController
                                                .text
                                                .trim();

                                            if (inputEmail.isEmpty) {
                                              if (mounted) {
                                                setState(() {
                                                  _isLoading = false;
                                                });
                                                showGlassSnackBar(
                                                  context,
                                                  message:
                                                      'Имэйл хаяг оруулна уу',
                                                  icon: Icons.error,
                                                  iconColor: Colors.red,
                                                );
                                              }
                                              return;
                                            }

                                            if (!RegExp(
                                              r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                            ).hasMatch(inputEmail)) {
                                              if (mounted) {
                                                setState(() {
                                                  _isLoading = false;
                                                });
                                                showGlassSnackBar(
                                                  context,
                                                  message:
                                                      'Зөв имэйл хаяг оруулна уу',
                                                  icon: Icons.error,
                                                  iconColor: Colors.red,
                                                );
                                              }
                                              return;
                                            }

                                            // Register in Wallet API first
                                            await ApiService.registerWalletUser(
                                              utas: inputPhone,
                                              mail: inputEmail,
                                            );
                                          }

                                          // Get saved address to send with login
                                          // Backend will also check saved address in user profile if not provided
                                          var savedBairId =
                                              await StorageService.getWalletBairId();
                                          var savedDoorNo =
                                              await StorageService.getWalletDoorNo();

                                          // If address not in local storage, try to get from previous login response
                                          // This handles cases where address was saved to backend but not to local storage
                                          if (savedBairId == null ||
                                              savedDoorNo == null) {
                                            print(
                                              '📍 [LOGIN] Address not in local storage, backend will use saved address from profile',
                                            );
                                          }

                                          // Try to login - backend automatically handles billing connection
                                          print(
                                            '🔐 [LOGIN] Attempting login with phone: $inputPhone',
                                          );
                                          print(
                                            '🔐 [LOGIN] Sending address - bairId: $savedBairId, doorNo: $savedDoorNo',
                                          );

                                          final loginResponse =
                                              await ApiService.loginUser(
                                                utas: inputPhone,
                                                bairId: savedBairId,
                                                doorNo: savedDoorNo,
                                              );

                                          print(
                                            '✅ [LOGIN] Login response received',
                                          );
                                          print(
                                            '   - Success: ${loginResponse['success']}',
                                          );
                                          print(
                                            '   - Has token: ${loginResponse['token'] != null}',
                                          );
                                          print(
                                            '   - Has result: ${loginResponse['result'] != null}',
                                          );
                                          print(
                                            '   - Has billingInfo: ${loginResponse['billingInfo'] != null}',
                                          );

                                          // Verify token was saved before proceeding
                                          final tokenSaved =
                                              await StorageService.isLoggedIn();
                                          print(
                                            '🔑 [LOGIN] Token saved check: $tokenSaved',
                                          );

                                          if (!tokenSaved) {
                                            throw Exception(
                                              'Токен хадгалахад алдаа гарлаа. Дахин оролдоно уу.',
                                            );
                                          }

                                          if (mounted) {
                                            // Check if user has address in their profile
                                            // The login response has walletBairId and walletDoorNo
                                            bool hasAddress = false;

                                            if (loginResponse['result'] !=
                                                null) {
                                              final userData =
                                                  loginResponse['result'];
                                              final walletBairId =
                                                  userData['walletBairId']
                                                      ?.toString();
                                              final walletDoorNo =
                                                  userData['walletDoorNo']
                                                      ?.toString();

                                              if (walletBairId != null &&
                                                  walletBairId.isNotEmpty &&
                                                  walletDoorNo != null &&
                                                  walletDoorNo.isNotEmpty) {
                                                // Save address from user profile to local storage
                                                await StorageService.saveWalletAddress(
                                                  bairId: walletBairId,
                                                  doorNo: walletDoorNo,
                                                );
                                                hasAddress = true;
                                                print(
                                                  '📍 [LOGIN] Address found in user profile: $walletBairId / $walletDoorNo',
                                                );

                                                // If billingInfo is not in response but we have address,
                                                // the backend should have fetched it automatically
                                                // If not, we'll fetch it manually as fallback
                                                if (loginResponse['billingInfo'] ==
                                                    null) {
                                                  print(
                                                    '⚠️ [LOGIN] Address exists but billingInfo missing - will fetch manually',
                                                  );
                                                }
                                              } else {
                                                // Check if address is already saved locally
                                                hasAddress =
                                                    await StorageService.hasSavedAddress();
                                                print(
                                                  '📍 [LOGIN] Address not in profile, checking local storage: $hasAddress',
                                                );
                                              }
                                            } else {
                                              // Fallback to local storage check
                                              hasAddress =
                                                  await StorageService.hasSavedAddress();
                                              print(
                                                '📍 [LOGIN] No user data in response, checking local storage: $hasAddress',
                                              );
                                            }

                                            await StorageService.savePhoneNumber(
                                              inputPhone,
                                            );

                                            final taniltsuulgaKharakhEsekh =
                                                await StorageService.getTaniltsuulgaKharakhEsekh();

                                            print(
                                              '📍 [LOGIN] Final hasAddress: $hasAddress',
                                            );

                                            print(
                                              '📍 [LOGIN] Has saved address: $hasAddress',
                                            );
                                            if (hasAddress) {
                                              final bairId =
                                                  await StorageService.getWalletBairId();
                                              final doorNo =
                                                  await StorageService.getWalletDoorNo();
                                              print(
                                                '📍 [LOGIN] Saved address - bairId: $bairId, doorNo: $doorNo',
                                              );
                                            }

                                            setState(() {
                                              _isLoading = false;
                                              _showEmailField = false;
                                            });
                                            showGlassSnackBar(
                                              context,
                                              message: 'Нэвтрэлт амжилттай',
                                              icon: Icons.check_outlined,
                                              iconColor: Colors.green,
                                            );

                                            try {
                                              await SocketService.instance
                                                  .connect();
                                            } catch (e) {
                                              print(
                                                'Failed to connect socket: $e',
                                              );
                                            }

                                            // Backend now automatically handles billing connection
                                            // Check billingInfo in response to see if billing was connected
                                            if (loginResponse['billingInfo'] !=
                                                null) {
                                              final billingInfo =
                                                  loginResponse['billingInfo'];
                                              final billingConnected =
                                                  loginResponse['billingConnected'] ==
                                                  true;

                                              print(
                                                '✅ [LOGIN] Billing info received from backend',
                                              );
                                              print(
                                                '   - Billing ID: ${billingInfo['billingId']}',
                                              );
                                              print(
                                                '   - Billing Name: ${billingInfo['billingName']}',
                                              );
                                              print(
                                                '   - Customer Name: ${billingInfo['customerName']}',
                                              );
                                              print(
                                                '   - Billing Connected: $billingConnected',
                                              );

                                              if (!billingConnected &&
                                                  loginResponse['connectionError'] !=
                                                      null) {
                                                print(
                                                  '⚠️ [LOGIN] Billing connection failed: ${loginResponse['connectionError']}',
                                                );
                                              }
                                            } else {
                                              // No billingInfo in response
                                              // Check if user has address - backend should have used it automatically
                                              if (hasAddress) {
                                                print(
                                                  '⚠️ [LOGIN] User has address but no billingInfo in response',
                                                );
                                                print(
                                                  '   Backend should have automatically fetched billing using saved address',
                                                );
                                                print(
                                                  '   Attempting to fetch billing manually...',
                                                );

                                                // Try to fetch billing manually using the address from profile
                                                try {
                                                  final bairId =
                                                      await StorageService.getWalletBairId();
                                                  final doorNo =
                                                      await StorageService.getWalletDoorNo();

                                                  if (bairId != null &&
                                                      doorNo != null) {
                                                    await ApiService.fetchWalletBilling(
                                                      bairId: bairId,
                                                      doorNo: doorNo,
                                                    );
                                                    print(
                                                      '✅ [LOGIN] Billing fetched manually after login',
                                                    );
                                                  }
                                                } catch (e) {
                                                  print(
                                                    '⚠️ [LOGIN] Could not fetch billing manually: $e',
                                                  );
                                                  // This is not critical - user can still use the app
                                                }
                                              } else {
                                                print(
                                                  'ℹ️ [LOGIN] No billing info in response (user may not have address)',
                                                );
                                              }
                                            }

                                            // Navigate to home
                                            final targetRoute =
                                                taniltsuulgaKharakhEsekh
                                                ? '/ekhniikh'
                                                : '/nuur';

                                            if (!hasAddress) {
                                              // If user doesn't have address, show address selection screen
                                              // Address selection will fetch billing data separately
                                              print(
                                                '📍 [LOGIN] No saved address, showing address selection screen',
                                              );
                                              await context.push<bool>(
                                                '/address_selection',
                                              );
                                            }

                                            // Navigate to home (whether address was selected or not)
                                            print(
                                              '🚀 [LOGIN] Navigating to: $targetRoute',
                                            );
                                            try {
                                              context.go(targetRoute);
                                              print(
                                                '✅ [LOGIN] Navigation successful',
                                              );
                                            } catch (e) {
                                              print(
                                                '❌ [LOGIN] Navigation error: $e',
                                              );
                                              // Try alternative navigation method
                                              if (mounted) {
                                                Navigator.of(
                                                  context,
                                                ).pushNamedAndRemoveUntil(
                                                  targetRoute,
                                                  (route) => false,
                                                );
                                              }
                                            }

                                            WidgetsBinding.instance
                                                .addPostFrameCallback((_) {
                                                  Future.delayed(
                                                    const Duration(
                                                      milliseconds: 800,
                                                    ),
                                                    () {
                                                      if (mounted) {
                                                        _showModalAfterNavigation();
                                                      }
                                                    },
                                                  );
                                                });
                                          }
                                        } catch (e) {
                                          if (mounted) {
                                            setState(() {
                                              _isLoading = false;
                                            });

                                            String errorMessage = e.toString();
                                            if (errorMessage.startsWith(
                                              'Exception: ',
                                            )) {
                                              errorMessage = errorMessage
                                                  .substring(11);
                                            }
                                            if (errorMessage.isEmpty) {
                                              errorMessage =
                                                  "Нэвтрэхэд алдаа гарлаа";
                                            }

                                            // If login fails because user is not registered, show email field
                                            if (errorMessage.contains(
                                                  'бүртгэлгүй',
                                                ) ||
                                                errorMessage.contains(
                                                  'бүртгэлтэй биш',
                                                ) ||
                                                errorMessage.contains(
                                                  'not found',
                                                ) ||
                                                errorMessage.contains(
                                                  'олдсонгүй',
                                                )) {
                                              setState(() {
                                                _showEmailField = true;
                                              });
                                              errorMessage =
                                                  "Хэтэвчний системд бүртгэлгүй байна. Имэйл хаягаа оруулна уу.";
                                            }

                                            showGlassSnackBar(
                                              context,
                                              message: errorMessage,
                                              icon: Icons.error,
                                              iconColor: Colors.red,
                                            );
                                          }
                                        }
                                      },
                                child: Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.symmetric(vertical: 12.h),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFCAD2DB),
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                  child: _isLoading
                                      ? Center(
                                          child: SizedBox(
                                            height: 20.h,
                                            width: 20.w,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              valueColor:
                                                  const AlwaysStoppedAnimation<
                                                    Color
                                                  >(Colors.black),
                                            ),
                                          ),
                                        )
                                      : Text(
                                          _showEmailField
                                              ? 'Бүртгүүлэх'
                                              : 'Нэвтрэх',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 15.sp,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '© 2025 Powered by Zevtabs LLC',
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  color: Colors.grey,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                'Version 1.0',
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  color: Colors.grey,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom painter for iOS Face ID icon
class FaceIdIconPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  FaceIdIconPainter({required this.color, this.strokeWidth = 3.0});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final faceWidth = size.width * 0.5;
    final faceHeight = size.height * 0.5;

    // Draw corner frame segments
    final cornerLength = size.width * 0.25;
    final cornerThickness = strokeWidth * 1.5;

    // Top-left corner
    final topLeftPath = Path()
      ..moveTo(centerX - faceWidth / 2, centerY - faceHeight / 2 - cornerLength)
      ..lineTo(centerX - faceWidth / 2, centerY - faceHeight / 2)
      ..lineTo(
        centerX - faceWidth / 2 - cornerLength,
        centerY - faceHeight / 2,
      );
    canvas.drawPath(topLeftPath, paint..strokeWidth = cornerThickness);

    // Top-right corner
    final topRightPath = Path()
      ..moveTo(centerX + faceWidth / 2, centerY - faceHeight / 2 - cornerLength)
      ..lineTo(centerX + faceWidth / 2, centerY - faceHeight / 2)
      ..lineTo(
        centerX + faceWidth / 2 + cornerLength,
        centerY - faceHeight / 2,
      );
    canvas.drawPath(topRightPath, paint..strokeWidth = cornerThickness);

    // Bottom-left corner
    final bottomLeftPath = Path()
      ..moveTo(centerX - faceWidth / 2, centerY + faceHeight / 2 + cornerLength)
      ..lineTo(centerX - faceWidth / 2, centerY + faceHeight / 2)
      ..lineTo(
        centerX - faceWidth / 2 - cornerLength,
        centerY + faceHeight / 2,
      );
    canvas.drawPath(bottomLeftPath, paint..strokeWidth = cornerThickness);

    // Bottom-right corner
    final bottomRightPath = Path()
      ..moveTo(centerX + faceWidth / 2, centerY + faceHeight / 2 + cornerLength)
      ..lineTo(centerX + faceWidth / 2, centerY + faceHeight / 2)
      ..lineTo(
        centerX + faceWidth / 2 + cornerLength,
        centerY + faceHeight / 2,
      );
    canvas.drawPath(bottomRightPath, paint..strokeWidth = cornerThickness);

    // Draw face features
    final facePaint = paint..strokeWidth = strokeWidth;

    // Left eye (vertical oval)
    final leftEyeRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(centerX - faceWidth * 0.2, centerY - faceHeight * 0.15),
        width: faceWidth * 0.15,
        height: faceWidth * 0.2,
      ),
      const Radius.circular(100),
    );
    canvas.drawRRect(leftEyeRect, facePaint);

    // Right eye (vertical oval)
    final rightEyeRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(centerX + faceWidth * 0.2, centerY - faceHeight * 0.15),
        width: faceWidth * 0.15,
        height: faceWidth * 0.2,
      ),
      const Radius.circular(100),
    );
    canvas.drawRRect(rightEyeRect, facePaint);

    // Nose (vertical oval, slightly offset to left)
    final noseRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(centerX - faceWidth * 0.05, centerY),
        width: faceWidth * 0.12,
        height: faceWidth * 0.25,
      ),
      const Radius.circular(100),
    );
    canvas.drawRRect(noseRect, facePaint);

    // Smile (upward-curving arc)
    final smilePath = Path();
    smilePath.addArc(
      Rect.fromCenter(
        center: Offset(centerX, centerY + faceHeight * 0.1),
        width: faceWidth * 0.6,
        height: faceHeight * 0.4,
      ),
      -0.3,
      0.6,
    );
    canvas.drawPath(smilePath, facePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
