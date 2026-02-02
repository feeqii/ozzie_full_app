import 'package:flutter/material.dart';

import '../../core/theme/app_text_styles.dart';

class ParentPlaceholderScreen extends StatelessWidget {
  const ParentPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Parent Placeholder', style: AppTextStyles.title),
      ),
    );
  }
}
