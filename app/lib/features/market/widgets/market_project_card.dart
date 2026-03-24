import 'package:flutter/material.dart';
import '../../../shared/widgets/vcc_card.dart';
import '../models/market_filter.dart';

class MarketProjectCard extends StatefulWidget {
  final MarketProjectItem project;
  final VoidCallback? onTap;

  const MarketProjectCard({
    super.key,
    required this.project,
    this.onTap,
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
        child: VccProjectCard(
          title: widget.project.title,
          description: widget.project.description,
          amount: widget.project.budgetDisplay,
          matchScore: widget.project.matchScore,
          tags: widget.project.techRequirements,
          footerInfo:
              '${widget.project.viewCount}浏览 · ${widget.project.bidCount}投标${widget.project.ownerName != null ? ' · ${widget.project.ownerName}' : ''}',
        ),
      ),
    );
  }
}
