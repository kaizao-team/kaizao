import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/vcc_button.dart';
import '../models/acceptance_models.dart';

class RevisionRequestSheet extends StatefulWidget {
  final List<AcceptanceItem> items;
  final Future<bool> Function(String description, List<String> relatedItemIds)
      onSubmit;

  const RevisionRequestSheet({
    super.key,
    required this.items,
    required this.onSubmit,
  });

  @override
  State<RevisionRequestSheet> createState() => _RevisionRequestSheetState();
}

class _RevisionRequestSheetState extends State<RevisionRequestSheet> {
  final _descController = TextEditingController();
  final Set<String> _selectedItems = {};
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _descController.addListener(_onTextChanged);
  }

  void _onTextChanged() => setState(() {});

  @override
  void dispose() {
    _descController.removeListener(_onTextChanged);
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_descController.text.trim().isEmpty) return;
    setState(() => _isSubmitting = true);
    final success = await widget.onSubmit(
      _descController.text.trim(),
      _selectedItems.toList(),
    );
    if (!mounted) return;
    if (success) {
      Navigator.pop(context, true);
    } else {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.gray300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '提交修改请求',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.black),
            ),
            const SizedBox(height: 16),
            const Text('问题描述',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray700)),
            const SizedBox(height: 8),
            TextField(
              controller: _descController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: '请描述需要修改的内容...',
                hintStyle:
                    const TextStyle(fontSize: 14, color: AppColors.gray400),
                filled: true,
                fillColor: AppColors.gray50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: AppColors.gray200, width: 0.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: AppColors.gray200, width: 0.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: AppColors.accent, width: 1),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('关联验收条目（可选）',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray700)),
            const SizedBox(height: 8),
            ...widget.items.map((item) => CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  activeColor: AppColors.accent,
                  title: Text(item.description,
                      style: const TextStyle(fontSize: 13)),
                  value: _selectedItems.contains(item.id),
                  onChanged: (v) {
                    setState(() {
                      if (v == true) {
                        _selectedItems.add(item.id);
                      } else {
                        _selectedItems.remove(item.id);
                      }
                    });
                  },
                )),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: VccButton(
                text: '提交修改请求',
                isLoading: _isSubmitting,
                onPressed: _descController.text.trim().isEmpty
                    ? null
                    : _submit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
