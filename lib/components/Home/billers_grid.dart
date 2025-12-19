import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sukh_app/components/Home/biller_card.dart';
import 'package:sukh_app/widgets/optimized_glass.dart';
import 'package:sukh_app/utils/responsive_helper.dart';

class BillersGrid extends StatefulWidget {
  final List<Map<String, dynamic>> billers;
  final VoidCallback onDevelopmentTap;
  final VoidCallback? onBillerTap;

  const BillersGrid({
    super.key,
    required this.billers,
    required this.onDevelopmentTap,
    this.onBillerTap,
  });

  @override
  State<BillersGrid> createState() => _BillersGridState();
}

class _BillersGridState extends State<BillersGrid> {
  @override
  Widget build(BuildContext context) {
    // Take first 5 billers (3 in first row, 2 in second row)
    final allBillers = widget.billers.take(5).toList();
    final firstRowBillers = allBillers.take(3).toList();
    final secondRowBillers = allBillers.skip(3).take(2).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Payment Services Grid
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.responsiveSpacing(
              small: 16,
              medium: 18,
              large: 20,
              tablet: 22,
              veryNarrow: 12,
            ),
          ),
          child: Container(
            margin: EdgeInsets.only(
              bottom: context.responsiveSpacing(
                small: 12,
                medium: 14,
                large: 16,
                tablet: 18,
                veryNarrow: 10,
              ),
            ),
            child: OptimizedGlass(
              borderRadius: BorderRadius.circular(12.r),
              child: Container(
                padding: EdgeInsets.symmetric(
                  vertical: context.responsiveSpacing(
                    small: 6,
                    medium: 8,
                    large: 10,
                    tablet: 12,
                    veryNarrow: 4,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // First row: 3 items
                    if (firstRowBillers.isNotEmpty) ...[
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: context.responsiveSpacing(
                            small: 8,
                            medium: 10,
                            large: 12,
                            tablet: 14,
                            veryNarrow: 6,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: firstRowBillers
                              .map(
                                (biller) => Expanded(
                                  child: BillerCard(
                                    biller: biller,
                                    onTapCallback: widget.onDevelopmentTap,
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ],

                    // Second row: 2 items centered with same width as first row items
                    if (secondRowBillers.isNotEmpty) ...[
                      SizedBox(
                        height: context.responsiveSpacing(
                          small: 6,
                          medium: 8,
                          large: 10,
                          tablet: 12,
                          veryNarrow: 4,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: context.responsiveSpacing(
                            small: 8,
                            medium: 10,
                            large: 12,
                            tablet: 14,
                            veryNarrow: 6,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Add flex spacer on left
                            Spacer(flex: 1),
                            // Two items with same width as first row
                            ...secondRowBillers
                                .map(
                                  (biller) => Expanded(
                                    flex: 2,
                                    child: BillerCard(
                                      biller: biller,
                                      onTapCallback: widget.onDevelopmentTap,
                                    ),
                                  ),
                                )
                                .toList(),
                            // Add flex spacer on right
                            Spacer(flex: 1),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
