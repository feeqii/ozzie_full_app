import 'package:flutter/material.dart';

import '../../core/theme/app_text_styles.dart';

class AuthPlaceholderScreen extends StatelessWidget {
  const AuthPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Auth Placeholder', style: AppTextStyles.title),
      ),
    );
  }
}
