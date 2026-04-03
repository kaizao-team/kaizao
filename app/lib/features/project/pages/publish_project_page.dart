import 'package:flutter/material.dart';

import '../../post/pages/post_page.dart';

class PublishProjectPage extends StatelessWidget {
  const PublishProjectPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PostPage(
      onCompleted: () => Navigator.pop(context),
    );
  }
}
