import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/vcc_input.dart';
import '../../../shared/widgets/vcc_card.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _searchController = TextEditingController();
  bool _hasSearched = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('广场')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: VccInput(
              isSearch: true,
              hint: '搜索项目、技能、开发者...',
              controller: _searchController,
              onSubmitted: (value) => setState(() => _hasSearched = true),
            ),
          ),
          if (!_hasSearched) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('热门搜索', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.gray800)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['Flutter开发', '小程序', 'AI助手', 'UI设计', '数据分析', '全栈开发']
                        .map((s) => GestureDetector(
                              onTap: () {
                                _searchController.text = s;
                                setState(() => _hasSearched = true);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.gray100,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(s, style: const TextStyle(fontSize: 14, color: AppColors.gray600)),
                              ),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
          ] else
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: 5,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) => VccProjectCard(
                  title: 'AI智能客服系统开发',
                  description: '需要一款基于大模型的智能客服系统，支持多轮对话、知识库管理',
                  amount: '\u00a55,000-8,000',
                  matchScore: 92 - index * 5,
                  tags: const ['React', 'GPT-4', 'WebSocket'],
                  footerInfo: '需要：全栈开发 \u00b7 预计7天',
                  onTap: () {},
                ),
              ),
            ),
        ],
      ),
    );
  }
}
