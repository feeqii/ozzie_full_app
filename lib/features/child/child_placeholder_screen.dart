import 'package:flutter/material.dart';

import '../../core/theme/app_text_styles.dart';

class ChildPlaceholderScreen extends StatelessWidget {
  const ChildPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Child Placeholder', style: AppTextStyles.title),
      ),
    );
  }
}
