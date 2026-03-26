import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../models/prd_models.dart';

class PrdModuleTree extends StatelessWidget {
  final List<PrdModule> modules;
  final ValueChanged<String> onCardTap;

  const PrdModuleTree({
    super.key,
    required this.modules,
    required this.onCardTap,
  });

  static const _moduleIcons = {
    'lock': Icons.lock_outlined,
    'home': Icons.home_outlined,
    'business': Icons.business_center_outlined,
    'person': Icons.person_outline,
  };

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      minScale: 0.6,
      maxScale: 2.0,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.black,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.description_outlined, size: 18, color: AppColors.white),
                  SizedBox(width: 8),
                  Text('PRD', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.white)),
                ],
              ),
            ),
            ...modules.map((module) => _ModuleNode(
                  module: module,
                  icon: _moduleIcons[module.icon] ?? Icons.widgets_outlined,
                  onCardTap: onCardTap,
                )),
          ],
        ),
      ),
    );
  }
}

class _ModuleNode extends StatefulWidget {
  final PrdModule module;
  final IconData icon;
  final ValueChanged<String> onCardTap;

  const _ModuleNode({
    required this.module,
    required this.icon,
    required this.onCardTap,
  });

  @override
  State<_ModuleNode> createState() => _ModuleNodeState();
}

class _ModuleNodeState extends State<_ModuleNode> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 2,
          height: 24,
          color: AppColors.gray300,
        ),
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.gray200),
              boxShadow: const [BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.04), blurRadius: 4, offset: Offset(0, 2))],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.accentLight,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Icon(widget.icon, size: 16, color: AppColors.accent),
                ),
                const SizedBox(width: 10),
                Text(
                  widget.module.name,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.black),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.gray100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${widget.module.cards.length}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.gray500),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  size: 18,
                  color: AppColors.gray400,
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox(width: double.infinity),
          secondChild: _buildCardList(),
          crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 260),
        ),
      ],
    );
  }

  Widget _buildCardList() {
    return Padding(
      padding: const EdgeInsets.only(left: 40),
      child: Column(
        children: widget.module.cards.map((card) {
          return Column(
            children: [
              Row(
                children: [
                  Container(width: 16, height: 1, color: AppColors.gray300),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => widget.onCardTap(card.id),
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: card.isCompleted ? AppColors.gray50 : AppColors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: card.isCompleted ? AppColors.success : _typeColor(card.type),
                            width: card.isCompleted ? 1 : 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            _TypeBadge(type: card.type),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                card.title,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: card.isCompleted ? AppColors.gray400 : AppColors.black,
                                  decoration: card.isCompleted ? TextDecoration.lineThrough : null,
                                ),
                              ),
                            ),
                            _PriorityBadge(priority: card.priority),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'event':
        return AppColors.earsEventStart;
      case 'state':
        return AppColors.earsStateStart;
      case 'response':
        return AppColors.earsUbiquitousStart;
      case 'action':
        return AppColors.earsOptionalStart;
      default:
        return AppColors.gray300;
    }
  }
}

class _TypeBadge extends StatelessWidget {
  final String type;

  const _TypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    final label = type.substring(0, 1).toUpperCase();
    Color color;
    switch (type) {
      case 'event':
        color = AppColors.earsEventStart;
      case 'state':
        color = AppColors.earsStateStart;
      case 'response':
        color = AppColors.earsUbiquitousStart;
      case 'action':
        color = AppColors.earsOptionalStart;
      default:
        color = AppColors.gray400;
    }

    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
      child: Center(
        child: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.white)),
      ),
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  final String priority;

  const _PriorityBadge({required this.priority});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (priority) {
      case 'P0':
        color = AppColors.error;
      case 'P1':
        color = AppColors.warning;
      default:
        color = AppColors.gray400;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        priority,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}
