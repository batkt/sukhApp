import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:sukh_app/constants/constants.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

class Burtguulekh extends StatefulWidget {
  const Burtguulekh({super.key});

  @override
  State<Burtguulekh> createState() => _BurtguulekhState();
}

class _BurtguulekhState extends State<Burtguulekh> {
  String? selectedDistrict;
  final List<String> districts = [
    'Сүхбаатар',
    'Чингэлтэй',
    'Баянгол',
    'Сонгинохайрхан',
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('lib/assets/img/main_background.png'),
              ),
            ),
          ),
          Container(color: Colors.black.withOpacity(0.5)),

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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 154 / 2),
                  Text(
                    'Бүртгэл',
                    style: TextStyle(color: AppColors.grayColor, fontSize: 36),
                    maxLines: 1,
                    softWrap: false,
                  ),
                  const SizedBox(height: 30),
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
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton2<String>(
                        isExpanded: true,
                        hint: Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              'Дүүрэг сонгох',
                              style: TextStyle(color: AppColors.grayColor),
                            ),
                          ),
                        ),
                        items: districts
                            .map(
                              (district) => DropdownMenuItem<String>(
                                value: district,
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    district,
                                    style: const TextStyle(
                                      color: AppColors.grayColor,
                                    ),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        value: selectedDistrict,
                        onChanged: (value) {
                          setState(() {
                            selectedDistrict = value;
                          });
                        },
                        buttonStyleData: ButtonStyleData(
                          height: 56,
                          padding: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            color: AppColors.inputGrayColor.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(100),
                          ),
                        ),
                        dropdownStyleData: DropdownStyleData(
                          decoration: BoxDecoration(
                            color: AppColors.inputGrayColor.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        iconStyleData: const IconStyleData(
                          icon: Icon(
                            Icons.arrow_drop_down,
                            color: Colors.white,
                          ),
                        ),
                      ),
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
                    child: GestureDetector(
                      child: AbsorbPointer(
                        child: TextField(
                          enabled: false,
                          decoration: InputDecoration(
                            hintText: 'Хотхон сонгох',
                            hintStyle: const TextStyle(
                              color: AppColors.grayColor,
                            ),
                            filled: true,
                            fillColor: AppColors.inputGrayColor.withOpacity(
                              0.5,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(100),
                              borderSide: BorderSide.none,
                            ),
                            suffixIcon: const Icon(
                              Icons.arrow_drop_down,
                              color: Colors.white,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 20,
                            ),
                          ),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
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
                    child: TextField(
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: 'СӨХ сонгох',
                        hintStyle: const TextStyle(color: AppColors.grayColor),
                        filled: true,
                        fillColor: AppColors.inputGrayColor.withOpacity(0.5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(100),
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: const Icon(
                          Icons.arrow_drop_down,
                          color: Colors.white,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 20,
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
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
                        onPressed: () {},
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
        ],
      ),
    );
  }
}
