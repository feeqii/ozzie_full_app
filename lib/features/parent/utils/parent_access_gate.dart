import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/parent_profile_provider.dart';

Future<void> openParentRouteWithPin({
  required BuildContext context,
  required WidgetRef ref,
  required String nextRoute,
  bool usePush = true,
}) async {
  final profile = await ref.read(parentProfileProvider.future);
  if (!context.mounted) {
    return;
  }

  if (profile == null) {
    context.go('/auth/entry');
    return;
  }

  final hasPin = (profile.pinHash ?? '').isNotEmpty;
  final route = Uri(
    path: hasPin ? '/parent/pin/verify' : '/parent/pin/setup',
    queryParameters: {'next': nextRoute},
  ).toString();

  if (usePush) {
    context.push(route);
  } else {
    context.go(route);
  }
}
