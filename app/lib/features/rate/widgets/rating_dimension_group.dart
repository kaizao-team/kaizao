import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../models/rate_models.dart';
import 'star_rating.dart';

class RatingDimensionGroup extends StatelessWidget {
  final List<RatingDimension> dimensions;
  final ValueChanged<MapEntry<int, double>> onDimensionChanged;

  const RatingDimensionGroup({
    super.key,
    required this.dimensions,
    required this.onDimensionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '分项评分',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.black,
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(dimensions.length, (index) {
          final dim = dimensions[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                SizedBox(
                  width: 90,
                  child: Text(
                    dim.name,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.gray600,
                    ),
                  ),
                ),
                Expanded(
                  child: StarRating(
                    rating: dim.rating,
                    starSize: 28,
                    onChanged: (r) =>
                        onDimensionChanged(MapEntry(index, r)),
                  ),
                ),
                SizedBox(
                  width: 30,
                  child: Text(
                    dim.rating > 0 ? dim.rating.toStringAsFixed(1) : '-',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: dim.rating > 0
                          ? AppColors.accentGold
                          : AppColors.gray400,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
