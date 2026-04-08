import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../models/market_filter.dart';
import 'market_budget_slider.dart';

class MarketFilterSheet extends StatefulWidget {
  final String selectedCategory;
  final double? budgetMin;
  final double? budgetMax;
  final ValueChanged<MarketFilterResult> onApply;

  const MarketFilterSheet({
    super.key,
    required this.selectedCategory,
    this.budgetMin,
    this.budgetMax,
    required this.onApply,
  });

  static Future<void> show(
    BuildContext context, {
    required String selectedCategory,
    double? budgetMin,
    double? budgetMax,
    required ValueChanged<MarketFilterResult> onApply,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      showDragHandle: false,
      builder: (_) => MarketFilterSheet(
        selectedCategory: selectedCategory,
        budgetMin: budgetMin,
        budgetMax: budgetMax,
        onApply: onApply,
      ),
    );
  }

  @override
  State<MarketFilterSheet> createState() => _MarketFilterSheetState();
}

class _MarketFilterSheetState extends State<MarketFilterSheet> {
  late String _category;
  double? _budgetMin;
  double? _budgetMax;

  @override
  void initState() {
    super.initState();
    _category = widget.selectedCategory;
    _budgetMin = widget.budgetMin;
    _budgetMax = widget.budgetMax;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.gray300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  '高级筛选',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.black,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '项目分类',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: MarketCategory.all.map((cat) {
                    final isSelected = cat.key == _category;
                    return GestureDetector(
                      onTap: () => setState(() => _category = cat.key),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isSelected ? AppColors.black : AppColors.gray100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          cat.name,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected
                                ? AppColors.white
                                : AppColors.gray600,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: MarketBudgetSlider(
              currentMin: _budgetMin,
              currentMax: _budgetMax,
              onChanged: (values) {
                _budgetMin = values.start;
                _budgetMax = values.end;
              },
            ),
          ),
          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _category = 'all';
                        _budgetMin = null;
                        _budgetMax = null;
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.black,
                      side: const BorderSide(color: AppColors.gray300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('重置'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onApply(
                        MarketFilterResult(
                          category: _category,
                          budgetMin: _budgetMin,
                          budgetMax: _budgetMax,
                        ),
                      );
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.black,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('应用筛选'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class MarketFilterResult {
  final String category;
  final double? budgetMin;
  final double? budgetMax;

  const MarketFilterResult({
    required this.category,
    this.budgetMin,
    this.budgetMax,
  });
}
