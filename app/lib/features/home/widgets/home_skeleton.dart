import 'package:flutter/material.dart';
import '../../../shared/widgets/vcc_loading.dart';

class HomeSkeleton extends StatelessWidget {
  const HomeSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 16),
          VccSkeleton(height: 140, borderRadius: 16),
          SizedBox(height: 28),
          VccSkeleton(width: 80, height: 20),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: VccSkeleton(height: 72, borderRadius: 10)),
              SizedBox(width: 8),
              Expanded(child: VccSkeleton(height: 72, borderRadius: 10)),
              SizedBox(width: 8),
              Expanded(child: VccSkeleton(height: 72, borderRadius: 10)),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: VccSkeleton(height: 72, borderRadius: 10)),
              SizedBox(width: 8),
              Expanded(child: VccSkeleton(height: 72, borderRadius: 10)),
              SizedBox(width: 8),
              Expanded(child: VccSkeleton(height: 72, borderRadius: 10)),
            ],
          ),
          SizedBox(height: 28),
          VccSkeleton(width: 80, height: 20),
          SizedBox(height: 12),
          VccCardSkeleton(),
          SizedBox(height: 12),
          VccCardSkeleton(),
        ],
      ),
    );
  }
}
