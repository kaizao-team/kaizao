import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';

class MarketBudgetSlider extends StatefulWidget {
  final double min;
  final double max;
  final double? currentMin;
  final double? currentMax;
  final ValueChanged<RangeValues> onChanged;

  const MarketBudgetSlider({
    super.key,
    this.min = 0,
    this.max = 200000,
    this.currentMin,
    this.currentMax,
    required this.onChanged,
  });

  @override
  State<MarketBudgetSlider> createState() => _MarketBudgetSliderState();
}

class _MarketBudgetSliderState extends State<MarketBudgetSlider> {
  late RangeValues _values;

  @override
  void initState() {
    super.initState();
    _values = RangeValues(
      widget.currentMin ?? widget.min,
      widget.currentMax ?? widget.max,
    );
  }

  @override
  void didUpdateWidget(covariant MarketBudgetSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentMin != widget.currentMin ||
        oldWidget.currentMax != widget.currentMax) {
      _values = RangeValues(
        widget.currentMin ?? widget.min,
        widget.currentMax ?? widget.max,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '预算范围',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.black,
              ),
            ),
            Text(
              '¥${_values.start.toStringAsFixed(0)} - ¥${_values.end.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.accent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: AppColors.black,
            inactiveTrackColor: AppColors.gray200,
            thumbColor: AppColors.white,
            overlayColor: const Color.fromRGBO(17, 17, 17, 0.1),
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(
              enabledThumbRadius: 10,
              elevation: 3,
            ),
            rangeThumbShape: const RoundRangeSliderThumbShape(
              enabledThumbRadius: 10,
              elevation: 3,
            ),
            rangeTrackShape: const RoundedRectRangeSliderTrackShape(),
            showValueIndicator: ShowValueIndicator.onDrag,
            valueIndicatorColor: AppColors.black,
            valueIndicatorTextStyle: const TextStyle(
              fontSize: 12,
              color: AppColors.white,
            ),
          ),
          child: RangeSlider(
            values: _values,
            min: widget.min,
            max: widget.max,
            divisions: 200,
            labels: RangeLabels(
              '¥${_values.start.toStringAsFixed(0)}',
              '¥${_values.end.toStringAsFixed(0)}',
            ),
            onChanged: (values) {
              setState(() => _values = values);
            },
            onChangeEnd: (values) {
              widget.onChanged(values);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '¥${widget.min.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.gray400,
                ),
              ),
              Text(
                '¥${widget.max.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.gray400,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
