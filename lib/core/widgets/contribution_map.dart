import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class ContributionMap extends StatelessWidget {
  final List<int> contributions; // List of contribution counts
  final int weeksCount;

  const ContributionMap({
    Key? key,
    required this.contributions,
    this.weeksCount = 20,
  }) : super(key: key);

  Color _getCellColor(int count) {
    if (count == 0) return AppColors.surfaceLight;
    if (count <= 2) return AppColors.greenAccent.withOpacity(0.3);
    if (count <= 5) return AppColors.greenAccent.withOpacity(0.5);
    if (count <= 8) return AppColors.greenAccent.withOpacity(0.75);
    return AppColors.greenAccent;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(weeksCount, (weekIdx) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.0),
                child: Column(
                  children: List.generate(7, (dayIdx) {
                    final cellIdx = weekIdx * 7 + dayIdx;
                    final count = cellIdx < contributions.length ? contributions[cellIdx] : 0;
                    
                    return GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('$count contributions on Day ${cellIdx + 1}'),
                            duration: const Duration(seconds: 1),
                            backgroundColor: AppColors.surfaceLight,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        );
                      },
                      child: Container(
                        width: 12,
                        height: 12,
                        margin: const EdgeInsets.symmetric(vertical: 2.0),
                        decoration: BoxDecoration(
                          color: _getCellColor(count),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    );
                  }),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Less', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
              SizedBox(width: 4),
              _LegendCell(color: AppColors.surfaceLight),
              SizedBox(width: 2),
              _LegendCell(color: Color(0x4D2ECC71)),
              SizedBox(width: 2),
              _LegendCell(color: Color(0x802ECC71)),
              SizedBox(width: 2),
              _LegendCell(color: Color(0xC02ECC71)),
              SizedBox(width: 2),
              _LegendCell(color: AppColors.greenAccent),
              SizedBox(width: 4),
              Text('More', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
            ],
          )
        ],
      ),
    );
  }
}

class _LegendCell extends StatelessWidget {
  final Color color;

  const _LegendCell({Key? key, required this.color}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
