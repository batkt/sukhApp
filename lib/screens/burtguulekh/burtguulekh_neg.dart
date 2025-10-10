import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:sukh_app/constants/constants.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'burtguulekh_khoyor.dart';

class Burtguulekh_Neg extends StatefulWidget {
  const Burtguulekh_Neg({super.key});

  @override
  State<Burtguulekh_Neg> createState() => _BurtguulekhState();
}

class _BurtguulekhState extends State<Burtguulekh_Neg> {
  final _formKey = GlobalKey<FormState>();
  final GlobalKey<FormFieldState<String>> _districtFieldKey =
      GlobalKey<FormFieldState<String>>();
  final GlobalKey<FormFieldState<String>> _khotkhonFieldKey =
      GlobalKey<FormFieldState<String>>();

  String? selectedDistrict;
  String? selectedKhotkhon;
  String? selectedSOKH;

  bool isDistrictOpen = false;
  bool isKhotkhonOpen = false;
  bool isSOKHOpen = false;

  final List<String> districts = [
    'Сүхбаатар',
    'Хан-Уул',
    'Чингэлтэй',
    'Баянзүрх',
    'Баянгол',
    'Сонгинохайрхан',
    'Налайх',
    'Багахангай',
    'Багануур',
  ];

  List<String> khotkhons = ['test', 'test'];
  List<String> sokhs = ['test', 'test'];

  bool isLoadingKhotkhon = false;
  bool isLoadingSOKH = false;

  Future<void> _loadKhotkhons(String district) async {
    setState(() {
      isLoadingKhotkhon = true;
      selectedKhotkhon = null;
      selectedSOKH = null;
      khotkhons = [];
      sokhs = [];
    });

    try {
      await Future.delayed(const Duration(seconds: 1));

      setState(() {
        khotkhons = ['Хотхон 1', 'Хотхон 2', 'Хотхон 3'];
        isLoadingKhotkhon = false;
      });
    } catch (e) {
      setState(() {
        isLoadingKhotkhon = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Хотхон мэдээлэл татахад алдаа гарлаа'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _loadSOKHs(String khotkhon) async {
    setState(() {
      isLoadingSOKH = true;
      selectedSOKH = null;
      sokhs = [];
    });

    try {
      await Future.delayed(const Duration(seconds: 1)); // Simulating API call

      setState(() {
        sokhs = ['СӨХ 1', 'СӨХ 2', 'СӨХ 3'];
        isLoadingSOKH = false;
      });
    } catch (e) {
      setState(() {
        isLoadingSOKH = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('СӨХ мэдээлэл татахад алдаа гарлаа'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
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
        MaterialPageRoute(builder: (context) => const Burtguulekh_Khoyor()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image
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
                    const SizedBox(height: 120 / 2),
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
                      '1/4',
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
                        key: _districtFieldKey,
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
                        hint: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Align(
                            alignment: Alignment.centerLeft,
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
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
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
                              ),
                            )
                            .toList(),
                        value: selectedDistrict,
                        onChanged: (value) {
                          setState(() {
                            selectedDistrict = value;
                          });
                          // Clear error when value is selected
                          _districtFieldKey.currentState?.validate();
                          if (value != null) {
                            _loadKhotkhons(value);
                          }
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '                                            Дүүрэг сонгоно уу';
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
                            isDistrictOpen
                                ? Icons.arrow_drop_up
                                : Icons.arrow_drop_down,
                            color: Colors.white,
                          ),
                        ),
                        onMenuStateChange: (isOpen) {
                          setState(() {
                            isDistrictOpen = isOpen;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    GestureDetector(
                      onTap: () {
                        if (selectedDistrict == null) {
                          _districtFieldKey.currentState?.validate();
                          _districtFieldKey.currentState?.didChange(
                            selectedDistrict,
                          );

                          setState(() {});
                        }
                      },
                      child: AbsorbPointer(
                        absorbing: selectedDistrict == null,
                        child: DropdownButtonFormField2<String>(
                          key: _khotkhonFieldKey,
                          isExpanded: true,
                          decoration: InputDecoration(
                            contentPadding: EdgeInsets.zero,
                            filled: true,
                            fillColor: AppColors.inputGrayColor.withOpacity(
                              0.5,
                            ),
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
                          ),
                          hint: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                isLoadingKhotkhon
                                    ? 'Уншиж байна...'
                                    : 'Хотхон сонгох',
                                style: const TextStyle(
                                  color: AppColors.grayColor,
                                ),
                              ),
                            ),
                          ),
                          items: khotkhons
                              .map(
                                (khotkhon) => DropdownMenuItem<String>(
                                  value: khotkhon,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        khotkhon,
                                        style: const TextStyle(
                                          color: AppColors.grayColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                          value: selectedKhotkhon,
                          onChanged:
                              (selectedDistrict == null || isLoadingKhotkhon)
                              ? null
                              : (value) {
                                  setState(() {
                                    selectedKhotkhon = value;
                                  });
                                  // Clear error when value is selected
                                  _khotkhonFieldKey.currentState?.validate();
                                  if (value != null) {
                                    _loadSOKHs(value);
                                  }
                                },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return '                                          Хотхон сонгоно уу';
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
                              isKhotkhonOpen
                                  ? Icons.arrow_drop_up
                                  : Icons.arrow_drop_down,
                              color: Colors.white,
                            ),
                          ),
                          onMenuStateChange: (isOpen) {
                            setState(() {
                              isKhotkhonOpen = isOpen;
                            });
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // SÖХ Dropdown
                    GestureDetector(
                      onTap: () {
                        if (selectedDistrict == null) {
                          _districtFieldKey.currentState?.validate();
                          _districtFieldKey.currentState?.didChange(
                            selectedDistrict,
                          );
                          setState(() {});
                        } else if (selectedKhotkhon == null) {
                          _khotkhonFieldKey.currentState?.validate();
                          _khotkhonFieldKey.currentState?.didChange(
                            selectedKhotkhon,
                          );
                          setState(() {});
                        }
                      },
                      child: AbsorbPointer(
                        absorbing:
                            selectedDistrict == null ||
                            selectedKhotkhon == null,
                        child: Container(
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
                              fillColor: AppColors.inputGrayColor.withOpacity(
                                0.5,
                              ),
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  isLoadingSOKH
                                      ? 'Уншиж байна...'
                                      : 'СӨХ сонгох',
                                  style: const TextStyle(
                                    color: AppColors.grayColor,
                                  ),
                                ),
                              ),
                            ),
                            items: sokhs.map((sokh) {
                              return DropdownMenuItem<String>(
                                value: sokh,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      sokh,
                                      style: const TextStyle(
                                        color: AppColors.grayColor,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                            value: selectedSOKH,
                            onChanged:
                                (selectedDistrict == null || isLoadingSOKH)
                                ? null
                                : (value) {
                                    setState(() {
                                      selectedSOKH = value;
                                    });
                                  },
                            validator: (value) {
                              if (selectedDistrict == null) {
                                return null;
                              }
                              if (selectedKhotkhon == null) {
                                return null;
                              }
                              if (value == null || value.isEmpty) {
                                return 'СӨХ сонгоно уу';
                              }
                              return null;
                            },
                            buttonStyleData: const ButtonStyleData(
                              height: 56,
                              padding: EdgeInsets.only(right: 11),
                            ),
                            dropdownStyleData: DropdownStyleData(
                              decoration: BoxDecoration(
                                color: AppColors.inputGrayColor.withOpacity(
                                  0.9,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            iconStyleData: IconStyleData(
                              icon: Icon(
                                isSOKHOpen
                                    ? Icons.arrow_drop_up
                                    : Icons.arrow_drop_down,
                                color: Colors.white,
                              ),
                            ),
                            onMenuStateChange: (isOpen) {
                              setState(() {
                                isSOKHOpen = isOpen;
                              });
                            },
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
                            shadowColor: Colors.black.withOpacity(0.3),
                            elevation: 8,
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
