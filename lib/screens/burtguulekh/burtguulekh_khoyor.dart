import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';
import 'package:sukh_app/constants/constants.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

class AppBackground extends StatelessWidget {
  final Widget child;
  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('lib/assets/img/background_image.png'),
            fit: BoxFit.none,
            scale: 3,
          ),
        ),
        child: child,
      ),
    );
  }
}

class Burtguulekh_Khoyor extends StatefulWidget {
  const Burtguulekh_Khoyor({super.key});

  @override
  State<Burtguulekh_Khoyor> createState() => _BurtguulekhState();
}

class _BurtguulekhState extends State<Burtguulekh_Khoyor> {
  final _formKey = GlobalKey<FormState>();

  String? selectedDistrict;
  String? selectedToot;
  String? selectedSOKH;

  bool isTootOpen = false;
  bool isKhotkhonOpen = false;
  bool isSOKHOpen = false;

  List<String> toot = ['Toot 1', 'Toot 2'];
  List<String> sokhs = ['test', 'test'];
  bool isLoadingToot = false;

  final TextEditingController ovogController = TextEditingController();
  final TextEditingController nerController = TextEditingController();
  final TextEditingController registerController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    ovogController.addListener(() => setState(() {}));
    nerController.addListener(() => setState(() {}));
    registerController.addListener(() => setState(() {}));
    emailController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    ovogController.dispose();
    nerController.dispose();
    registerController.dispose();
    emailController.dispose();
    super.dispose();
  }

  void _validateAndSubmit() {
    if (_formKey.currentState!.validate()) {
      context.push('/burtguulekh_guraw');
    }
  }

  InputDecoration _inputDecoration(
    String hint,
    TextEditingController controller,
  ) {
    return InputDecoration(
      contentPadding: const EdgeInsets.symmetric(horizontal: 25, vertical: 16),
      filled: true,
      fillColor: AppColors.inputGrayColor.withOpacity(0.5),
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white70),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(100),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(100),
        borderSide: const BorderSide(color: AppColors.grayColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(100),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(100),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
      errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: AppBackground(
          child: Stack(
            children: [
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final keyboardHeight = MediaQuery.of(
                      context,
                    ).viewInsets.bottom;
                    return SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: 50,
                          right: 50,
                          top: 40,
                          bottom: keyboardHeight > 0 ? keyboardHeight + 20 : 40,
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  minHeight: 80,
                                  maxHeight: 154,
                                  minWidth: 154,
                                  maxWidth: 154,
                                ),
                                child: AspectRatio(
                                  aspectRatio: 1,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(36),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(
                                        sigmaX: 10,
                                        sigmaY: 10,
                                      ),
                                      child: Container(
                                        color: Colors.white.withOpacity(0.2),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 30),
                              const Text(
                                'Бүртгэл',
                                style: TextStyle(
                                  color: AppColors.grayColor,
                                  fontSize: 36,
                                ),
                                maxLines: 1,
                                softWrap: false,
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                '2/3',
                                style: TextStyle(
                                  color: AppColors.grayColor,
                                  fontSize: 16,
                                ),
                                maxLines: 1,
                                softWrap: false,
                              ),
                              const SizedBox(height: 20),
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(100),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      offset: const Offset(0, 10),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: DropdownButtonFormField2<String>(
                                  isExpanded: true,
                                  decoration: InputDecoration(
                                    contentPadding: EdgeInsets.zero,
                                    filled: true,
                                    fillColor: AppColors.inputGrayColor
                                        .withOpacity(0.5),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(100),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(100),
                                      borderSide: const BorderSide(
                                        color: AppColors.grayColor,
                                        width: 1.5,
                                      ),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(100),
                                      borderSide: const BorderSide(
                                        color: Colors.redAccent,
                                        width: 1.5,
                                      ),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(100),
                                      borderSide: const BorderSide(
                                        color: Colors.redAccent,
                                        width: 1.5,
                                      ),
                                    ),
                                    errorStyle: const TextStyle(
                                      color: Colors.redAccent,
                                      fontSize: 14,
                                    ),
                                  ),
                                  hint: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                    child: Text(
                                      isLoadingToot
                                          ? 'Уншиж байна...'
                                          : 'Тоот сонгох',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                  items: toot
                                      .map(
                                        (item) => DropdownMenuItem<String>(
                                          value: item,
                                          child: Text(
                                            item,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  selectedItemBuilder: (context) {
                                    return toot.map((item) {
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                        ),
                                        child: Text(
                                          item,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      );
                                    }).toList();
                                  },
                                  value: toot.contains(selectedToot)
                                      ? selectedToot
                                      : null,
                                  onChanged: isLoadingToot || toot.isEmpty
                                      ? null
                                      : (value) => setState(
                                          () => selectedToot = value,
                                        ),
                                  validator: (value) =>
                                      (value == null || value.isEmpty)
                                      ? '                                             Тоот сонгоно уу'
                                      : null,
                                  buttonStyleData: const ButtonStyleData(
                                    height: 56,
                                    padding: EdgeInsets.only(right: 11),
                                  ),
                                  dropdownStyleData: DropdownStyleData(
                                    maxHeight: 300,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.inputGrayColor
                                          .withOpacity(0.95),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.2),
                                        width: 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.3),
                                          offset: const Offset(0, 8),
                                          blurRadius: 24,
                                          spreadRadius: 0,
                                        ),
                                      ],
                                    ),
                                  ),
                                  menuItemStyleData: MenuItemStyleData(
                                    height: 48,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    overlayColor:
                                        WidgetStateProperty.resolveWith<Color?>(
                                          (Set<WidgetState> states) {
                                            if (states.contains(
                                              WidgetState.hovered,
                                            )) {
                                              return Colors.white.withOpacity(
                                                0.1,
                                              );
                                            }
                                            if (states.contains(
                                              WidgetState.focused,
                                            )) {
                                              return Colors.white.withOpacity(
                                                0.15,
                                              );
                                            }
                                            return null;
                                          },
                                        ),
                                  ),
                                  iconStyleData: IconStyleData(
                                    icon: Icon(
                                      isTootOpen
                                          ? Icons.arrow_drop_up
                                          : Icons.arrow_drop_down,
                                      color: Colors.white,
                                    ),
                                  ),
                                  onMenuStateChange: (isOpen) =>
                                      setState(() => isTootOpen = isOpen),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                decoration: _boxShadowDecoration(),
                                child: TextFormField(
                                  controller: ovogController,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: _inputDecoration(
                                    'Овог',
                                    ovogController,
                                  ),
                                  validator: (value) =>
                                      value == null || value.trim().isEmpty
                                      ? '                                      Овог оруулна уу'
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                decoration: _boxShadowDecoration(),
                                child: TextFormField(
                                  controller: nerController,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: _inputDecoration(
                                    'Нэр',
                                    nerController,
                                  ),
                                  validator: (value) =>
                                      value == null || value.trim().isEmpty
                                      ? '                                        Нэр оруулна уу'
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                decoration: _boxShadowDecoration(),
                                child: TextFormField(
                                  controller: registerController,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: _inputDecoration(
                                    'Регистрийн дугаар',
                                    registerController,
                                  ),
                                  validator: (value) =>
                                      value == null || value.trim().isEmpty
                                      ? '             Регистрийн дугаар оруулна уу'
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                decoration: _boxShadowDecoration(),
                                child: TextFormField(
                                  controller: emailController,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: _inputDecoration(
                                    'И-Мэйл хаяг',
                                    emailController,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return '                        И-Мэйл хаяг оруулна уу';
                                    }
                                    final emailRegex = RegExp(
                                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                    );
                                    if (!emailRegex.hasMatch(value.trim())) {
                                      return '                                  Зөв И-Мэйл хаяг оруулна уу';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(100),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      offset: const Offset(0, 10),
                                      blurRadius: 8,
                                      spreadRadius: 0,
                                    ),
                                  ],
                                ),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _validateAndSubmit,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFCAD2DB),
                                      foregroundColor: Colors.black,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                        horizontal: 10,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          100,
                                        ),
                                      ),
                                      shadowColor: Colors.black.withOpacity(
                                        0.3,
                                      ),
                                      elevation: 8,
                                    ),
                                    child: const Text(
                                      'Үргэлжлүүлэх',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Positioned(
                top: 16,
                left: 16,
                child: SafeArea(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: IconButton(
                          padding: const EdgeInsets.only(left: 7),
                          constraints: const BoxConstraints(),
                          icon: const Icon(
                            Icons.arrow_back_ios,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: () {
                            context.pop();
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  BoxDecoration _boxShadowDecoration() {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(100),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.3),
          offset: const Offset(0, 10),
          blurRadius: 8,
        ),
      ],
    );
  }
}
