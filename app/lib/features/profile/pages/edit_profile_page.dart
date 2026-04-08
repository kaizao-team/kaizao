import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/local_avatar_picker.dart';
import '../../../shared/widgets/vcc_button.dart';
import '../../../shared/widgets/vcc_toast.dart';
import '../providers/profile_provider.dart';
import '../widgets/skill_tag_editor.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _nicknameController = TextEditingController();
  final _taglineController = TextEditingController();
  final _bioController = TextEditingController();
  String? _avatarUrl;
  bool _initialized = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _nicknameController.dispose();
    _taglineController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _initFields(ProfileState state) {
    if (_initialized) return;
    final p = state.profile;
    if (p == null) return;
    _nicknameController.text = p.nickname;
    _taglineController.text = p.tagline;
    _bioController.text = p.bio;
    _avatarUrl = p.avatar;
    _initialized = true;
  }

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final notifier = ref.read(profileProvider('me').notifier);
    final success = await notifier.updateProfile({
      'avatar_url': _avatarUrl ?? '',
      'nickname': _nicknameController.text.trim(),
      'tagline': _taglineController.text.trim(),
      'bio': _bioController.text.trim(),
    });

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      VccToast.show(context, message: '保存成功', type: VccToastType.success);
      Navigator.pop(context);
    } else {
      VccToast.show(context, message: '保存失败', type: VccToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileProvider('me'));
    _initFields(state);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '编辑资料',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      '保存',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.black,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          LocalAvatarPickerTrigger(
            value: _avatarUrl,
            title: _avatarUrl == null ? '选择头像' : '更换头像',
            hint:
                _avatarUrl == null ? '从本地头像里挑一个，资料页会立刻更新' : '当前资料和广场卡片都会使用这张头像',
            onChanged: (value) => setState(() => _avatarUrl = value),
            sheetTitle: '选择个人头像',
            avatarDiameter: 60,
          ),
          const SizedBox(height: 24),
          _buildField('昵称', _nicknameController, '输入你的昵称', maxLength: 20),
          const SizedBox(height: 20),
          _buildField(
            '一句话介绍',
            _taglineController,
            '如：全栈 Vibe Coder',
            maxLength: 30,
          ),
          const SizedBox(height: 20),
          _buildField(
            '个人简介',
            _bioController,
            '介绍你的经验和技能...',
            maxLines: 4,
            maxLength: 200,
          ),
          const SizedBox(height: 28),
          SkillTagEditor(
            skills: state.skills,
            onChanged: (skills) {
              ref.read(profileProvider('me').notifier).updateSkills(skills);
            },
          ),
          const SizedBox(height: 40),
          VccButton(text: '保存修改', onPressed: _save, isLoading: _isSaving),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
    int? maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.gray700,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          maxLength: maxLength,
          style: const TextStyle(fontSize: 15, color: AppColors.black),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 14, color: AppColors.gray400),
            filled: true,
            fillColor: AppColors.gray50,
            counterStyle: const TextStyle(
              fontSize: 11,
              color: AppColors.gray400,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.gray200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.gray200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.black, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
