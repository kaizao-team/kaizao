import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/vcc_button.dart';

class ProjectDetailPage extends StatefulWidget {
  final String? projectId;
  const ProjectDetailPage({super.key, this.projectId});

  @override
  State<ProjectDetailPage> createState() => _ProjectDetailPageState();
}

class _ProjectDetailPageState extends State<ProjectDetailPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('项目详情'),
        actions: [
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          // 项目概览卡片
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppShadows.shadow2,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 64,
                  height: 64,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: 0.68,
                        strokeWidth: 6,
                        backgroundColor: AppColors.gray200,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.brandPurple),
                      ),
                      const Text('68%', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.gray800)),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('完成 68%', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.gray800)),
                      SizedBox(height: 4),
                      Text('剩余 3 天 \u00b7 供给方：阿杰团队', style: TextStyle(fontSize: 14, color: AppColors.gray500)),
                      Text('里程碑：开发阶段', style: TextStyle(fontSize: 12, color: AppColors.gray400)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 子Tab栏
          TabBar(
            controller: _tabController,
            labelColor: AppColors.brandPurple,
            unselectedLabelColor: AppColors.gray400,
            labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            unselectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
            indicatorColor: AppColors.brandPurple,
            indicatorSize: TabBarIndicatorSize.label,
            tabs: const [
              Tab(text: '看板'),
              Tab(text: '里程碑'),
              Tab(text: 'PRD'),
              Tab(text: '文件'),
              Tab(text: '简报'),
            ],
          ),

          // Tab内容
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildBoardView(),
                const Center(child: Text('里程碑视图', style: TextStyle(fontSize: 16, color: AppColors.gray500))),
                const Center(child: Text('PRD文档', style: TextStyle(fontSize: 16, color: AppColors.gray500))),
                const Center(child: Text('项目文件', style: TextStyle(fontSize: 16, color: AppColors.gray500))),
                const Center(child: Text('AI每日简报', style: TextStyle(fontSize: 16, color: AppColors.gray500))),
              ],
            ),
          ),
        ],
      ),
      // 底部操作区
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: VccButton(text: '沟通', type: VccButtonType.secondary, onPressed: () {}),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: VccButton(text: '验收', onPressed: () {}),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBoardView() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildColumn('待办', 5, AppColors.gray400),
          const SizedBox(width: 12),
          _buildColumn('进行中', 3, AppColors.statusInProgress),
          const SizedBox(width: 12),
          _buildColumn('已完成', 20, AppColors.statusCompleted),
        ],
      ),
    );
  }

  Widget _buildColumn(String title, int count, Color color) {
    return SizedBox(
      width: 280,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$title($count)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.gray600)),
          const SizedBox(height: 8),
          ...List.generate(
            count > 3 ? 3 : count,
            (index) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border(left: BorderSide(color: color, width: 3)),
                boxShadow: AppShadows.shadow2,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('#T-${(index + 1).toString().padLeft(3, '0')}', style: const TextStyle(fontSize: 12, color: AppColors.gray400)),
                  const SizedBox(height: 4),
                  const Text('任务卡片标题', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.gray800)),
                  const SizedBox(height: 4),
                  const Text('预估 2h \u00b7 前端', style: TextStyle(fontSize: 12, color: AppColors.gray400)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
