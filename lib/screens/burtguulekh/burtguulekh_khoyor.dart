import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:sukh_app/constants/constants.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

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

  void _validateAndSubmit() {
    if (_formKey.currentState!.validate()) {
      // All fields are valid
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Бүх мэдээлэл зөв байна!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          // Dark overlay
          Container(color: Colors.black.withOpacity(0.5)),

          // Blurred white square
          Positioned(
            top: 88,
            left: (MediaQuery.of(context).size.width - 154) / 2,
            child: SizedBox(
              width: 154,
              height: 154,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(36),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(color: Colors.white.withOpacity(0.2)),
                ),
              ),
            ),
          ),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 40),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 200),
                    Text(
                      'Бүртгэл',
                      style: TextStyle(
                        color: AppColors.grayColor,
                        fontSize: 36,
                      ),
                      maxLines: 1,
                      softWrap: false,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '2/4',
                      style: TextStyle(
                        color: AppColors.grayColor,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      softWrap: false,
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
                          errorStyle: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 14,
                          ),
                          errorMaxLines: 2,
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
                            : null, // ✅ safe
                        onChanged: isLoadingToot || toot.isEmpty
                            ? null
                            : (value) {
                                setState(() {
                                  selectedToot = value;
                                });
                              },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '                                                Тоот сонгоно уу';
                          }
                          return null;
                        },
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
                        onMenuStateChange: (isOpen) {
                          setState(() {
                            isTootOpen = isOpen;
                          });
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
                          ),
                        ],
                      ),
                      child: TextFormField(
                        style: TextStyle(color: AppColors.grayColor),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 25,
                          ),
                          filled: true,
                          fillColor: AppColors.inputGrayColor.withOpacity(0.5),
                          hintText: 'Овог',
                          hintStyle: const TextStyle(
                            color: AppColors.grayColor,
                          ),
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
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '                                         Овог оруулна уу';
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
                          ),
                        ],
                      ),
                      child: TextFormField(
                        style: TextStyle(color: AppColors.grayColor),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 25,
                          ),
                          filled: true,
                          fillColor: AppColors.inputGrayColor.withOpacity(0.5),
                          hintText: 'Нэр',
                          hintStyle: const TextStyle(
                            color: AppColors.grayColor,
                          ),
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
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '                                          Нэр оруулна уу';
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
                          ),
                        ],
                      ),
                      child: TextFormField(
                        style: TextStyle(color: AppColors.grayColor),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 25,
                          ),
                          filled: true,
                          fillColor: AppColors.inputGrayColor.withOpacity(0.5),
                          hintText: 'Регистрийн дугаар',
                          hintStyle: const TextStyle(
                            color: AppColors.grayColor,
                          ),
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
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '                          Регистрийн дугаар оруулна уу';
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
                          ),
                        ],
                      ),
                      child: TextFormField(
                        style: TextStyle(color: AppColors.grayColor),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 25,
                          ),
                          filled: true,
                          fillColor: AppColors.inputGrayColor.withOpacity(0.5),
                          hintText: 'И-Мэйл хаяг',
                          hintStyle: const TextStyle(
                            color: AppColors.grayColor,
                          ),
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
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '                           И-Мэйл хаяг оруулна уу';
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
                          onPressed: () {
                            _validateAndSubmit();
                          },
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
}
