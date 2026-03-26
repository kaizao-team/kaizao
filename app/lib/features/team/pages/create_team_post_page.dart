import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/vcc_button.dart';
import '../../../shared/widgets/vcc_toast.dart';
import '../providers/team_provider.dart';

class CreateTeamPostPage extends ConsumerStatefulWidget {
  const CreateTeamPostPage({super.key});

  @override
  ConsumerState<CreateTeamPostPage> createState() => _CreateTeamPostPageState();
}

class _CreateTeamPostPageState extends ConsumerState<CreateTeamPostPage> {
  final _descController = TextEditingController();
  final _projectController = TextEditingController();
  final List<_RoleEntry> _roles = [
    _RoleEntry(name: '', ratio: 0),
  ];
  bool _isSubmitting = false;

  @override
  void dispose() {
    _descController.dispose();
    _projectController.dispose();
    super.dispose();
  }

  int get _totalRatio => _roles.fold<int>(0, (s, r) => s + r.ratio);
  bool get _isRatioValid => _totalRatio == 100;
  bool get _isFormValid =>
      _projectController.text.trim().isNotEmpty &&
      _roles.every((r) => r.name.trim().isNotEmpty) &&
      _isRatioValid;

  void _addRole() {
    setState(() => _roles.add(_RoleEntry(name: '', ratio: 0)));
  }

  void _removeRole(int index) {
    if (_roles.length <= 1) return;
    setState(() => _roles.removeAt(index));
  }

  Future<void> _submit() async {
    if (!_isFormValid || _isSubmitting) return;
    setState(() => _isSubmitting = true);

    final success = await ref.read(teamHallProvider.notifier).createPost({
      'project_name': _projectController.text.trim(),
      'description': _descController.text.trim(),
      'needed_roles': _roles
          .map((r) => {'name': r.name, 'ratio': r.ratio})
          .toList(),
    });

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      VccToast.show(context, message: '寻人帖发布成功', type: VccToastType.success);
      Navigator.pop(context);
    } else {
      VccToast.show(context, message: '发布失败', type: VccToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '发布寻人帖',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildLabel('关联项目'),
          const SizedBox(height: 8),
          TextField(
            controller: _projectController,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(fontSize: 15),
            decoration: _inputDecoration('选择或输入项目名称'),
          ),
          const SizedBox(height: 24),
          _buildLabel('描述'),
          const SizedBox(height: 8),
          TextField(
            controller: _descController,
            maxLines: 3,
            maxLength: 200,
            style: const TextStyle(fontSize: 15),
            decoration: _inputDecoration('描述你的需求和期望...'),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildLabel('所需角色'),
              const Spacer(),
              TextButton.icon(
                onPressed: _addRole,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('添加角色', style: TextStyle(fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...List.generate(_roles.length, (i) => _buildRoleRow(i)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _isRatioValid
                  ? AppColors.success.withValues(alpha: 0.06)
                  : AppColors.error.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  _isRatioValid
                      ? Icons.check_circle
                      : Icons.warning_amber_rounded,
                  size: 18,
                  color: _isRatioValid ? AppColors.success : AppColors.error,
                ),
                const SizedBox(width: 8),
                Text(
                  '分成总计：$_totalRatio%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _isRatioValid ? AppColors.success : AppColors.error,
                  ),
                ),
                if (!_isRatioValid) ...[
                  const Spacer(),
                  Text(
                    '需等于100%',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 32),
          VccButton(
            text: '发布寻人帖',
            isLoading: _isSubmitting,
            onPressed: _isFormValid ? _submit : null,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildRoleRow(int index) {
    final role = _roles[index];
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: TextField(
              onChanged: (val) => setState(() => _roles[index] =
                  _RoleEntry(name: val, ratio: role.ratio)),
              style: const TextStyle(fontSize: 14),
              decoration: _inputDecoration('角色名称'),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 80,
            child: TextField(
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(3),
              ],
              onChanged: (val) => setState(() => _roles[index] =
                  _RoleEntry(
                      name: role.name, ratio: int.tryParse(val) ?? 0)),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                suffixText: '%',
                hintText: '0',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.gray200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.gray200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.black, width: 1.5),
                ),
              ),
            ),
          ),
          if (_roles.length > 1)
            IconButton(
              onPressed: () => _removeRole(index),
              icon: const Icon(Icons.remove_circle_outline,
                  size: 20, color: AppColors.error),
            ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.gray700,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 14, color: AppColors.gray400),
      filled: true,
      fillColor: AppColors.gray50,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
    );
  }
}

class _RoleEntry {
  final String name;
  final int ratio;
  const _RoleEntry({required this.name, required this.ratio});
}
