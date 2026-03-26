import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../app/theme/app_colors.dart';
import '../models/team_models.dart';

class SplitRatioEditor extends StatelessWidget {
  final List<TeamMember> members;
  final ValueChanged<MapEntry<String, int>> onRatioChanged;

  const SplitRatioEditor({
    super.key,
    required this.members,
    required this.onRatioChanged,
  });

  int get _totalRatio => members.fold<int>(0, (s, m) => s + m.ratio);
  bool get _isValid => _totalRatio == 100;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '分成比例',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.black,
          ),
        ),
        const SizedBox(height: 12),
        ...members.map((m) => _MemberRatioRow(
              member: m,
              isOverLimit: !_isValid && m.ratio > 0,
              onChanged: (val) =>
                  onRatioChanged(MapEntry(m.id, val)),
            )),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: _isValid
                ? AppColors.success.withValues(alpha: 0.06)
                : AppColors.error.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _isValid
                  ? AppColors.success.withValues(alpha: 0.3)
                  : AppColors.error.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                _isValid ? Icons.check_circle : Icons.warning_amber_rounded,
                size: 18,
                color: _isValid ? AppColors.success : AppColors.error,
              ),
              const SizedBox(width: 8),
              Text(
                '总计：$_totalRatio%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _isValid ? AppColors.success : AppColors.error,
                ),
              ),
              if (!_isValid) ...[
                const Spacer(),
                Text(
                  _totalRatio > 100 ? '超出${_totalRatio - 100}%' : '差${100 - _totalRatio}%',
                  style: const TextStyle(fontSize: 12, color: AppColors.error),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _MemberRatioRow extends StatefulWidget {
  final TeamMember member;
  final bool isOverLimit;
  final ValueChanged<int> onChanged;

  const _MemberRatioRow({
    required this.member,
    required this.isOverLimit,
    required this.onChanged,
  });

  @override
  State<_MemberRatioRow> createState() => _MemberRatioRowState();
}

class _MemberRatioRowState extends State<_MemberRatioRow> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '${widget.member.ratio}');
  }

  @override
  void didUpdateWidget(covariant _MemberRatioRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.member.ratio != widget.member.ratio &&
        _controller.text != '${widget.member.ratio}') {
      _controller.text = '${widget.member.ratio}';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.member.nickname,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.black,
                  ),
                ),
                Text(
                  widget.member.role,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.gray400,
                  ),
                ),
              ],
            ),
          ),
          if (widget.member.isLeader)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.accentGold.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                '队长',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.accentGold,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          SizedBox(
            width: 70,
            child: TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(3),
              ],
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: widget.isOverLimit ? AppColors.error : AppColors.black,
              ),
              decoration: InputDecoration(
                suffixText: '%',
                suffixStyle: TextStyle(
                  fontSize: 14,
                  color: widget.isOverLimit ? AppColors.error : AppColors.gray500,
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: widget.isOverLimit ? AppColors.error : AppColors.gray200,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: widget.isOverLimit ? AppColors.error : AppColors.gray200,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: widget.isOverLimit ? AppColors.error : AppColors.black,
                    width: 1.5,
                  ),
                ),
              ),
              onChanged: (val) {
                final parsed = int.tryParse(val) ?? 0;
                widget.onChanged(parsed);
              },
            ),
          ),
        ],
      ),
    );
  }
}
