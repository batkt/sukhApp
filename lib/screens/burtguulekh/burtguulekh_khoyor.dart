import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:sukh_app/constants/constants.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'burtguulekh_guraw.dart';

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
    // Listen to changes to update the clear button visibility
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Бүх мэдээлэл зөв байна!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const Burtguulekh_Guraw()),
      );
    }
  }

  InputDecoration _inputDecoration(
    String hint,
    TextEditingController controller,
  ) {
    return InputDecoration(
      contentPadding: const EdgeInsets.symmetric(horizontal: 25),
      filled: true,
      fillColor: AppColors.inputGrayColor.withOpacity(0.5),
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.grayColor),
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
      suffixIcon: controller.text.isNotEmpty
          ? IconButton(
              icon: const Icon(Icons.clear, color: Colors.white70),
              onPressed: () => controller.clear(),
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('lib/assets/img/main_background.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(color: Colors.black.withOpacity(0.5)),
          Center(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: EdgeInsets.only(
                left: 50,
                right: 50,
                top: 40,
                bottom: MediaQuery.of(context).viewInsets.bottom + 100,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 154,
                      height: 154,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(36),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            color: Colors.white.withOpacity(0.2),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    Text(
                      'Бүртгэл',
                      style: TextStyle(
                        color: AppColors.grayColor,
                        fontSize: 36,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      '2/4',
                      style: TextStyle(
                        color: AppColors.grayColor,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 50),

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
                          fillColor: AppColors.inputGrayColor.withOpacity(0.5),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(100),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(100),
                            borderSide: const BorderSide(
                              color: Colors.white,
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
                        ),
                        hint: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              isLoadingToot ? 'Уншиж байна...' : 'Тоот сонгох',
                              style: const TextStyle(
                                color: AppColors.grayColor,
                              ),
                            ),
                          ),
                        ),
                        items: toot
                            .map(
                              (item) => DropdownMenuItem<String>(
                                value: item,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      item,
                                      style: const TextStyle(
                                        color: AppColors.grayColor,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        value: toot.contains(selectedToot)
                            ? selectedToot
                            : null,
                        onChanged: isLoadingToot || toot.isEmpty
                            ? null
                            : (value) => setState(() => selectedToot = value),
                        validator: (value) => (value == null || value.isEmpty)
                            ? 'Тоот сонгоно уу'
                            : null,
                        buttonStyleData: const ButtonStyleData(
                          height: 56,
                          padding: EdgeInsets.only(right: 11),
                        ),
                        dropdownStyleData: DropdownStyleData(
                          decoration: BoxDecoration(
                            color: AppColors.inputGrayColor.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(16),
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
                        style: const TextStyle(color: AppColors.grayColor),
                        decoration: _inputDecoration('Овог', ovogController),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Овог оруулна уу'
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Container(
                      decoration: _boxShadowDecoration(),
                      child: TextFormField(
                        controller: nerController,
                        style: const TextStyle(color: AppColors.grayColor),
                        decoration: _inputDecoration('Нэр', nerController),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Нэр оруулна уу'
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Container(
                      decoration: _boxShadowDecoration(),
                      child: TextFormField(
                        controller: registerController,
                        style: const TextStyle(color: AppColors.grayColor),
                        decoration: _inputDecoration(
                          'Регистрийн дугаар',
                          registerController,
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Регистрийн дугаар оруулна уу'
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Container(
                      decoration: _boxShadowDecoration(),
                      child: TextFormField(
                        controller: emailController,
                        style: const TextStyle(color: AppColors.grayColor),
                        decoration: _inputDecoration(
                          'И-Мэйл хаяг',
                          emailController,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'И-Мэйл хаяг оруулна уу';
                          }
                          final emailRegex = RegExp(
                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                          );
                          if (!emailRegex.hasMatch(value.trim())) {
                            return 'Зөв И-Мэйл хаяг оруулна уу';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 24),

                    Container(
                      decoration: _boxShadowDecoration(),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _validateAndSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFCAD2DB),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(100),
                            ),
                          ),
                          child: const Text(
                            'Үргэлжлүүлэх',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
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
