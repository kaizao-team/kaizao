import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/vcc_card.dart';
import '../models/market_filter.dart';

class MarketProjectCard extends StatefulWidget {
  final MarketProjectItem project;
  final VoidCallback? onTap;
  final bool isExpert;
  final String? aiTip;

  const MarketProjectCard({
    super.key,
    required this.project,
    this.onTap,
    this.isExpert = false,
    this.aiTip,
  });

  @override
  State<MarketProjectCard> createState() => _MarketProjectCardState();
}

class _MarketProjectCardState extends State<MarketProjectCard> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.98),
      onTapUp: (_) {
        setState(() => _scale = 1.0);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: Column(
          children: [
            VccProjectCard(
              title: widget.project.title,
              description: widget.project.description,
              amount: widget.project.budgetDisplay,
              matchScore:
                  widget.isExpert ? widget.project.matchScore : null,
              tags: widget.project.techRequirements,
              footerInfo:
                  '${widget.project.viewCount}浏览 · ${widget.project.bidCount}投标${widget.project.ownerName != null ? ' · ${widget.project.ownerName}' : ''}',
            ),
            if (widget.isExpert && widget.aiTip != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: const BoxDecoration(
                  color: AppColors.gray50,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome,
                        size: 14, color: AppColors.accent),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        widget.aiTip!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.gray600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
