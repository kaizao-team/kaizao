import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';

class PostAttachmentButton extends StatefulWidget {
  final ValueChanged<List<String>>? onFilesSelected;

  const PostAttachmentButton({super.key, this.onFilesSelected});

  @override
  State<PostAttachmentButton> createState() => _PostAttachmentButtonState();
}

class _PostAttachmentButtonState extends State<PostAttachmentButton> {
  final List<_MockFile> _files = [];
  bool _isUploading = false;

  void _pickFile() async {
    setState(() => _isUploading = true);

    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    setState(() {
      _files.add(_MockFile(
        name: '需求文档_${_files.length + 1}.pdf',
        size: '${(1.5 + _files.length * 0.3).toStringAsFixed(1)} MB',
      ));
      _isUploading = false;
    });

    widget.onFilesSelected?.call(_files.map((f) => f.name).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_files.isNotEmpty) ...[
          ..._files.map((file) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.gray50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.gray200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.insert_drive_file_outlined, size: 18, color: AppColors.gray500),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(file.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.black)),
                            Text(file.size, style: const TextStyle(fontSize: 11, color: AppColors.gray400)),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() => _files.remove(file));
                          widget.onFilesSelected?.call(_files.map((f) => f.name).toList());
                        },
                        child: const Icon(Icons.close, size: 16, color: AppColors.gray400),
                      ),
                    ],
                  ),
                ),
              )),
          const SizedBox(height: 4),
        ],
        GestureDetector(
          onTap: _isUploading ? null : _pickFile,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.gray300, style: BorderStyle.solid),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isUploading)
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.gray500),
                  )
                else
                  const Icon(Icons.attach_file, size: 16, color: AppColors.gray500),
                const SizedBox(width: 6),
                Text(
                  _isUploading ? '上传中...' : '添加附件',
                  style: const TextStyle(fontSize: 13, color: AppColors.gray600),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MockFile {
  final String name;
  final String size;
  const _MockFile({required this.name, required this.size});
}
