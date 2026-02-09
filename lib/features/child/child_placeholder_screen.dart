import 'package:flutter/material.dart';

import '../../core/ui/app_scaffold.dart';
import '../../core/ui/atlas_background.dart';

class ChildPlaceholderScreen extends StatelessWidget {
  const ChildPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      background: const AtlasBackground(seed: 3, intensity: 0.75, showGrid: false),
      body: Center(
        child: Text(
          'Child Placeholder',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
    );
  }
}
