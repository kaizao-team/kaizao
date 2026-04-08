import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../shared/skills/app_skill_registry.dart';
import '../models/profile_models.dart';

class SkillTagEditor extends StatefulWidget {
  final List<SkillTag> skills;
  final ValueChanged<List<SkillTag>> onChanged;
  final int maxCount;

  const SkillTagEditor({
    super.key,
    required this.skills,
    required this.onChanged,
    this.maxCount = 20,
  });

  @override
  State<SkillTagEditor> createState() => _SkillTagEditorState();
}

class _SkillTagEditorState extends State<SkillTagEditor> {
  late List<SkillTag> _skills;
  final _inputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _skills = List.from(widget.skills);
  }

  @override
  void didUpdateWidget(covariant SkillTagEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.skills != widget.skills) {
      setState(() {
        _skills = List.from(widget.skills);
      });
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _addSkill(String name) {
    if (name.trim().isEmpty) return;
    if (_skills.length >= widget.maxCount) return;
    if (_skills.any((s) => s.name == name.trim())) return;

    setState(() {
      _skills.add(
        SkillTag(
          id: 'skill_${DateTime.now().millisecondsSinceEpoch}',
          name: name.trim(),
        ),
      );
    });
    widget.onChanged(_skills);
    _inputController.clear();
  }

  void _removeSkill(String id) {
    setState(() {
      _skills.removeWhere((s) => s.id == id);
    });
    widget.onChanged(_skills);
  }

  @override
  Widget build(BuildContext context) {
    final existingNames = _skills.map((s) => s.name).toSet();
    final available = AppSkillRegistry.profilePresetSkills
        .map((definition) => definition.label)
        .where((s) => !existingNames.contains(s))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '技能标签',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.black,
              ),
            ),
            const Spacer(),
            Text(
              '${_skills.length}/${widget.maxCount}',
              style: const TextStyle(fontSize: 12, color: AppColors.gray400),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _skills.map((skill) {
            return Chip(
              label: Text(
                skill.name,
                style: const TextStyle(fontSize: 13, color: AppColors.black),
              ),
              deleteIcon: const Icon(Icons.close, size: 16),
              onDeleted: () => _removeSkill(skill.id),
              backgroundColor: AppColors.gray100,
              side: BorderSide.none,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            );
          }).toList(),
        ),
        if (_skills.length < widget.maxCount) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _inputController,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: '自定义技能标签',
                    hintStyle: const TextStyle(
                      fontSize: 14,
                      color: AppColors.gray400,
                    ),
                    filled: true,
                    fillColor: AppColors.gray50,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
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
                      borderSide: const BorderSide(color: AppColors.black),
                    ),
                  ),
                  onSubmitted: _addSkill,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _addSkill(_inputController.text),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.black,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child:
                      const Icon(Icons.add, size: 20, color: AppColors.white),
                ),
              ),
            ],
          ),
          if (available.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              '推荐技能',
              style: TextStyle(fontSize: 12, color: AppColors.gray400),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: available.take(10).map((name) {
                return GestureDetector(
                  onTap: () => _addSkill(name),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.gray200),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.add,
                          size: 14,
                          color: AppColors.gray500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.gray600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ],
    );
  }
}
