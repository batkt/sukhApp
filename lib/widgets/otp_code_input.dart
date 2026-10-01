import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sukh_app/constants/constants.dart';
import 'package:sukh_app/utils/theme_extensions.dart';

/// Баталгаажуулах кодын (OTP) оролт — НЭГ далд TextField-ийг [length] хайрцаг
/// болгон харуулна.
///
/// ЯАГААД: өмнө нь хайрцаг бүр тусдаа TextField байсан тул
///  - iOS/Android-ийн SMS кодын санал (autofill) зөвхөн идэвхтэй нэг хайрцгийг
///    бөглөдөг байв (9904 → «9»);
///  - устгахдаа хайрцаг бүр дээр дарж устгах шаардлагатай байв.
/// Нэг талбартай болсноор SMS-ийн кодыг дармагц бүх оронтой бөглөгдөж,
/// backspace нь хайрцаг дамжин ар тал руугаа устгана.
class OtpCodeInput extends StatefulWidget {
  final int length;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;

  /// Бүх орон бөглөгдөхөд дуудагдана (автоматаар илгээхэд)
  final ValueChanged<String>? onCompleted;
  final bool autofocus;
  final bool enabled;
  final bool hasError;

  const OtpCodeInput({
    super.key,
    this.length = 4,
    this.controller,
    this.focusNode,
    this.onChanged,
    this.onCompleted,
    this.autofocus = true,
    this.enabled = true,
    this.hasError = false,
  });

  @override
  State<OtpCodeInput> createState() => _OtpCodeInputState();
}

class _OtpCodeInputState extends State<OtpCodeInput> {
  late final TextEditingController _controller =
      widget.controller ?? TextEditingController();
  late final FocusNode _focus = widget.focusNode ?? FocusNode();
  String _umnukh = '';

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onText);
    _focus.addListener(_rebuild);
  }

  @override
  void dispose() {
    _controller.removeListener(_onText);
    _focus.removeListener(_rebuild);
    if (widget.controller == null) _controller.dispose();
    if (widget.focusNode == null) _focus.dispose();
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  void _onText() {
    final text = _controller.text;
    if (text == _umnukh) return;
    _umnukh = text;
    if (mounted) setState(() {});
    widget.onChanged?.call(text);
    if (text.length == widget.length) {
      widget.onCompleted?.call(text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final text = _controller.text;
    final idevkhteiIndex = text.length.clamp(0, widget.length - 1);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (!widget.enabled) return;
        _focus.requestFocus();
        // Курсорыг үргэлж төгсгөлд — дундах хайрцаг дээр дарсан ч дараалал алдагдахгүй
        _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
        SystemChannels.textInput.invokeMethod('TextInput.show');
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Далд жинхэнэ талбар: autofill (oneTimeCode), гар, backspace
          Opacity(
            opacity: 0,
            child: SizedBox(
              height: 1,
              child: TextField(
                controller: _controller,
                focusNode: _focus,
                autofocus: widget.autofocus,
                enabled: widget.enabled,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.oneTimeCode],
                enableInteractiveSelection: false,
                showCursor: false,
                maxLength: widget.length,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(widget.length),
                ],
                decoration: const InputDecoration(
                  counterText: '',
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(widget.length, (i) {
              final orson = i < text.length;
              final idevkhtei = _focus.hasFocus && i == idevkhteiIndex &&
                  text.length < widget.length;
              final khureeOngo = widget.hasError
                  ? const Color(0xFFE5484D)
                  : idevkhtei
                      ? AppColors.deepGreen
                      : orson
                          ? AppColors.deepGreen.withOpacity(0.35)
                          : (isDark
                              ? Colors.white.withOpacity(0.10)
                              : Colors.black.withOpacity(0.08));
              return AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 62.w,
                height: 64.w,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.05)
                      : const Color(0xFFF3F5F4),
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(color: khureeOngo, width: idevkhtei ? 2 : 1.5),
                ),
                child: orson
                    ? Text(
                        text[i],
                        style: TextStyle(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.w600,
                          color: context.textPrimaryColor,
                        ),
                      )
                    : idevkhtei
                        ? _Kursor(color: AppColors.deepGreen)
                        : null,
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _Kursor extends StatefulWidget {
  final Color color;
  const _Kursor({required this.color});

  @override
  State<_Kursor> createState() => _KursorState();
}

class _KursorState extends State<_Kursor> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _c,
      child: Container(width: 2, height: 26.w, color: widget.color),
    );
  }
}
