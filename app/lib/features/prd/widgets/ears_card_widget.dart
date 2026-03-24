import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../models/prd_models.dart';

class EarsCardWidget extends StatelessWidget {
  final EarsCard card;
  final bool isExpanded;
  final bool isDemander;
  final VoidCallback onToggle;
  final void Function(String criteriaId) onToggleCriteria;
  final void Function(String depId)? onDependencyTap;

  const EarsCardWidget({
    super.key,
    required this.card,
    required this.isExpanded,
    this.isDemander = true,
    required this.onToggle,
    required this.onToggleCriteria,
    this.onDependencyTap,
  });

  Color get _typeColor {
    switch (card.type) {
      case 'event':
        return AppColors.earsEventStart;
      case 'state':
        return AppColors.earsStateStart;
      case 'response':
        return AppColors.earsUbiquitousStart;
      case 'action':
        return AppColors.earsOptionalStart;
      default:
        return AppColors.gray400;
    }
  }

  String get _typeLabel {
    switch (card.type) {
      case 'event':
        return 'Event';
      case 'state':
        return 'State';
      case 'response':
        return 'Response';
      case 'action':
        return 'Action';
      default:
        return card.type;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: card.isCompleted ? AppColors.gray50 : AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: card.isCompleted ? AppColors.gray200 : _typeColor,
          width: card.isCompleted ? 1 : 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onToggle,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _typeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _typeLabel,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _typeColor),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: card.priority == 'P0'
                          ? AppColors.errorBg
                          : card.priority == 'P1'
                              ? AppColors.warningBg
                              : AppColors.gray100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      card.priority,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: card.priority == 'P0'
                            ? AppColors.error
                            : card.priority == 'P1'
                                ? AppColors.warning
                                : AppColors.gray500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      card.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: card.isCompleted ? AppColors.gray400 : AppColors.black,
                        decoration: card.isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ),
                  if (card.acceptanceCriteria.isNotEmpty)
                    Text(
                      '${card.completedCriteria}/${card.acceptanceCriteria.length}',
                      style: const TextStyle(fontSize: 11, color: AppColors.gray400),
                    ),
                  const SizedBox(width: 4),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 260),
                    child: const Icon(Icons.expand_more, size: 20, color: AppColors.gray400),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: _buildExpandedContent(),
            crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 260),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedContent() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(color: AppColors.gray200, height: 1),
          const SizedBox(height: 12),
          Text(card.description, style: const TextStyle(fontSize: 13, color: AppColors.gray600, height: 1.5)),
          const SizedBox(height: 14),
          _EarsSection(label: 'Event', content: card.event, color: AppColors.earsEventStart),
          _EarsSection(label: 'Action', content: card.action, color: AppColors.earsOptionalStart),
          _EarsSection(label: 'Response', content: card.response, color: AppColors.earsUbiquitousStart),
          _EarsSection(label: 'State', content: card.stateChange, color: AppColors.earsStateStart),
          if (!isDemander) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: card.techTags.map((tag) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.gray100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(tag, style: const TextStyle(fontSize: 11, color: AppColors.gray600)),
                  )).toList(),
            ),
            const SizedBox(height: 8),
            Text('预估工时: ${card.effortHours}h', style: const TextStyle(fontSize: 12, color: AppColors.gray500)),
          ],
          if (card.dependencies.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Text('依赖: ', style: TextStyle(fontSize: 12, color: AppColors.gray500)),
                ...card.dependencies.map((dep) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: GestureDetector(
                        onTap: () => onDependencyTap?.call(dep),
                        child: Text(dep, style: const TextStyle(fontSize: 12, color: AppColors.accent, decoration: TextDecoration.underline)),
                      ),
                    )),
              ],
            ),
          ],
          if (card.acceptanceCriteria.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text('验收标准', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.black)),
            const SizedBox(height: 8),
            ...card.acceptanceCriteria.map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: GestureDetector(
                    onTap: () => onToggleCriteria(c.id),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          margin: const EdgeInsets.only(top: 1),
                          decoration: BoxDecoration(
                            color: c.checked ? AppColors.black : AppColors.white,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: c.checked ? AppColors.black : AppColors.gray300),
                          ),
                          child: c.checked
                              ? const Icon(Icons.check, size: 14, color: AppColors.white)
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            c.content,
                            style: TextStyle(
                              fontSize: 13,
                              color: c.checked ? AppColors.gray400 : AppColors.gray700,
                              decoration: c.checked ? TextDecoration.lineThrough : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            children: card.roles.map((role) {
              final label = _roleLabel(role);
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.accentLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(label, style: const TextStyle(fontSize: 11, color: AppColors.accent)),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'frontend':
        return '前端';
      case 'backend':
        return '后端';
      case 'algorithm':
        return '算法';
      case 'design':
        return '设计';
      default:
        return role;
    }
  }
}

class _EarsSection extends StatelessWidget {
  final String label;
  final String content;
  final Color color;

  const _EarsSection({
    required this.label,
    required this.content,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (content.isEmpty) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 16,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
                const SizedBox(height: 2),
                Text(content, style: const TextStyle(fontSize: 12, color: AppColors.gray600, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
