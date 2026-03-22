import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/vcc_button.dart';

class PublishProjectPage extends StatefulWidget {
  const PublishProjectPage({super.key});

  @override
  State<PublishProjectPage> createState() => _PublishProjectPageState();
}

class _PublishProjectPageState extends State<PublishProjectPage> {
  int _currentStep = 0;
  String? _selectedCategory;

  final List<Map<String, dynamic>> _categories = [
    {'id': 'app', 'label': 'APP开发', 'icon': Icons.phone_android},
    {'id': 'web', 'label': '网站开发', 'icon': Icons.language},
    {'id': 'miniprogram', 'label': '小程序', 'icon': Icons.widgets_outlined},
    {'id': 'design', 'label': 'UI设计', 'icon': Icons.palette_outlined},
    {'id': 'data', 'label': '数据分析', 'icon': Icons.analytics_outlined},
    {'id': 'consult', 'label': '技术指导', 'icon': Icons.school_outlined},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('发布需求'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消', style: TextStyle(color: AppColors.gray500)),
          ),
        ],
      ),
      body: Column(
        children: [
          // 步骤指示器
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            child: Row(
              children: List.generate(5, (index) {
                final isActive = index <= _currentStep;
                return Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: index == _currentStep ? 10 : 8,
                        height: index == _currentStep ? 10 : 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: isActive ? AppGradients.primaryButton : null,
                          border: isActive ? null : Border.all(color: AppColors.gray300, width: 1),
                        ),
                      ),
                      if (index < 4)
                        Expanded(
                          child: Container(
                            height: 2,
                            color: index < _currentStep ? AppColors.brandPurple : AppColors.gray200,
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ),
          ),

          // 步骤内容
          Expanded(
            child: IndexedStack(
              index: _currentStep,
              children: [
                _buildCategoryStep(),
                _buildAiChatStep(),
                _buildPrdPreviewStep(),
                _buildEditStep(),
                _buildBudgetStep(),
              ],
            ),
          ),

          // 底部按钮
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: VccButton(
                text: _currentStep == 4 ? '确认发布需求' : '下一步',
                onPressed: _selectedCategory != null || _currentStep > 0
                    ? () {
                        if (_currentStep < 4) {
                          setState(() => _currentStep++);
                        } else {
                          Navigator.pop(context);
                        }
                      }
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryStep() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 165.5 / 96,
        ),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = _selectedCategory == cat['id'];
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = cat['id'] as String),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFF8F7FF) : AppColors.gray50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.brandPurple : Colors.transparent,
                  width: isSelected ? 2 : 0,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(cat['icon'] as IconData, size: 32, color: isSelected ? AppColors.brandPurple : AppColors.gray500),
                  const SizedBox(height: 8),
                  Text(
                    cat['label'] as String,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? AppColors.brandPurple : AppColors.gray700,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAiChatStep() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('AI对话式需求录入', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.gray800)),
          const SizedBox(height: 8),
          const Text('请描��你想要实现的功能，AI会帮你梳理需求', style: TextStyle(fontSize: 14, color: AppColors.gray500)),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.gray50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('AI对话内容区域', style: TextStyle(fontSize: 14, color: AppColors.gray400)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrdPreviewStep() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('AI生成PRD预览', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.gray800)),
          const SizedBox(height: 8),
          const Text('以下是AI根据对话生成的项目需求文档', style: TextStyle(fontSize: 14, color: AppColors.gray500)),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: AppShadows.shadow2,
              ),
              child: const Text('PRD文档预览内容', style: TextStyle(fontSize: 14, color: AppColors.gray400)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditStep() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('编辑/确认PRD', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.gray800)),
          const SizedBox(height: 8),
          const Text('你可以对生成的PRD进行修改和确认', style: TextStyle(fontSize: 14, color: AppColors.gray500)),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.gray200),
              ),
              child: const Text('可编辑的PRD内容', style: TextStyle(fontSize: 14, color: AppColors.gray400)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetStep() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('设置预算与撮合偏好', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.gray800)),
          const SizedBox(height: 8),
          const Text('设置项目预算范围和匹配偏好', style: TextStyle(fontSize: 14, color: AppColors.gray500)),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: AppShadows.shadow2,
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('预算范围', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.gray800)),
                SizedBox(height: 12),
                Text('AI推荐预算：\u00a53,000 - \u00a55,000', style: TextStyle(fontSize: 14, color: AppColors.brandPurple)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
