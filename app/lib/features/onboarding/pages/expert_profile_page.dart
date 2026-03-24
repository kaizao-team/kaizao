import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/routes.dart';
import '../../../shared/widgets/vcc_button.dart';
import '../../../shared/widgets/vcc_step_indicator.dart';
import '../../../shared/widgets/vcc_toast.dart';
import '../providers/onboarding_provider.dart';

/// ONBOARD-005: 专家资料编辑引导
class ExpertProfilePage extends ConsumerStatefulWidget {
  const ExpertProfilePage({super.key});

  @override
  ConsumerState<ExpertProfilePage> createState() => _ExpertProfilePageState();
}

class _ExpertProfilePageState extends ConsumerState<ExpertProfilePage> {
  final _nicknameController = TextEditingController();
  final Set<String> _selectedSkills = {};
  final Set<String> _selectedTools = {};
  int _selfRating = 3;
  String _availability = '';
  double _rateMin = 200;
  double _rateMax = 800;

  final _skills = ['Flutter', 'React', 'Vue.js', 'Python', 'Go', 'Rust', 'UI设计', 'AI/ML', '后端', '全栈'];
  final _tools = ['Git', 'Figma', 'Notion', 'Cursor', 'VS Code', 'Docker', 'Jira'];
  final _availabilities = ['1周内', '1-2周', '1个月内', '随时'];

  @override
  void initState() {
    super.initState();
    final draft = ref.read(onboardingProvider).draft;
    _nicknameController.text = draft['nickname'] as String? ?? '';
    if (draft['skills'] is List) {
      _selectedSkills.addAll((draft['skills'] as List).cast<String>());
    }
    if (draft['tools'] is List) {
      _selectedTools.addAll((draft['tools'] as List).cast<String>());
    }
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  bool get _isValid =>
      _nicknameController.text.trim().length >= 2 &&
      _selectedSkills.isNotEmpty &&
      _selectedTools.isNotEmpty;

  Future<void> _next() async {
    if (!_isValid) return;
    final notifier = ref.read(onboardingProvider.notifier);
    final success = await notifier.submitData({
      'nickname': _nicknameController.text.trim(),
      'skills': _selectedSkills.toList(),
      'tools': _selectedTools.toList(),
      'self_rating': _selfRating,
      'availability': _availability,
      'rate_min': _rateMin,
      'rate_max': _rateMax,
    });
    if (!mounted) return;
    if (success) {
      await notifier.nextStep();
      if (mounted) context.go(RoutePaths.expertOnboarding2);
    } else {
      VccToast.show(context, message: '保存失败，已记录草稿', type: VccToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: VccStepIndicator(
                totalSteps: 3,
                currentStep: 0,
                labels: const ['专家资料', '补充信息', '等级评定'],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '完善你的专家资料',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.black),
                    ),
                    const SizedBox(height: 24),

                    // Nickname
                    const Text('昵称', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.gray700)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nicknameController,
                      maxLength: 16,
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(fontSize: 16, color: AppColors.black),
                      decoration: InputDecoration(
                        hintText: '2-16个字符',
                        counterText: '${_nicknameController.text.length}/16',
                        counterStyle: const TextStyle(fontSize: 12, color: AppColors.gray400),
                        filled: true,
                        fillColor: AppColors.gray50,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.gray200)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.gray200)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.black, width: 1.5)),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Skills
                    const Text('擅长经验（至少选1个）', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.gray700)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: _skills.map((s) {
                        final sel = _selectedSkills.contains(s);
                        return GestureDetector(
                          onTap: () => setState(() => sel ? _selectedSkills.remove(s) : _selectedSkills.add(s)),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: sel ? AppColors.black : AppColors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: sel ? AppColors.black : AppColors.gray200),
                            ),
                            child: Text(s, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: sel ? AppColors.white : AppColors.gray600)),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // Tools
                    const Text('常用工具（至少选1个）', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.gray700)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: _tools.map((t) {
                        final sel = _selectedTools.contains(t);
                        return GestureDetector(
                          onTap: () => setState(() => sel ? _selectedTools.remove(t) : _selectedTools.add(t)),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: sel ? AppColors.black : AppColors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: sel ? AppColors.black : AppColors.gray200),
                            ),
                            child: Text(t, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: sel ? AppColors.white : AppColors.gray600)),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // Self rating
                    const Text('能力自评', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.gray700)),
                    const SizedBox(height: 8),
                    Row(
                      children: List.generate(5, (i) {
                        return GestureDetector(
                          onTap: () => setState(() => _selfRating = i + 1),
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Icon(
                              i < _selfRating ? Icons.star : Icons.star_border,
                              size: 32,
                              color: i < _selfRating ? AppColors.accentGold : AppColors.gray300,
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 20),

                    // Availability
                    const Text('可接单排期（选填）', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.gray700)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _availabilities.map((a) {
                        final sel = _availability == a;
                        return GestureDetector(
                          onTap: () => setState(() => _availability = a),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: sel ? AppColors.black : AppColors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: sel ? AppColors.black : AppColors.gray200),
                            ),
                            child: Text(a, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: sel ? AppColors.white : AppColors.gray600)),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // Rate
                    const Text('服务预算（选填）', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.gray700)),
                    const SizedBox(height: 4),
                    Text('¥${_rateMin.toInt()} - ¥${_rateMax.toInt()}/天', style: const TextStyle(fontSize: 14, color: AppColors.gray600)),
                    RangeSlider(
                      values: RangeValues(_rateMin, _rateMax),
                      min: 100,
                      max: 5000,
                      divisions: 49,
                      activeColor: AppColors.black,
                      inactiveColor: AppColors.gray200,
                      onChanged: (v) => setState(() { _rateMin = v.start; _rateMax = v.end; }),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: VccButton(
                text: '下一步',
                onPressed: _isValid ? _next : null,
                isLoading: state.isLoading,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
