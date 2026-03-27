import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/vcc_card.dart';
import '../models/home_models.dart';

class ExpertHomeDemands extends StatelessWidget {
  final List<RecommendedDemand> demands;

  const ExpertHomeDemands({super.key, required this.demands});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 28, 20, 12),
          child: Text(
            '推荐项目',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.black,
            ),
          ),
        ),
        ...demands.map(
          (d) => Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: VccProjectCard(
              title: d.title,
              description: d.description,
              amount: d.budgetDisplay,
              matchScore: d.matchScore,
              tags: d.techRequirements,
              onTap: () => context.push('/projects/${d.id}'),
            ),
          ),
        ),
      ],
    );
  }
}
