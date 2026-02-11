import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ui_overhaul_flags.dart';

final uiOverhaulFlagsProvider = Provider<UiOverhaulFlags>((ref) {
  return UiOverhaulFlags.fromEnvironment();
});
