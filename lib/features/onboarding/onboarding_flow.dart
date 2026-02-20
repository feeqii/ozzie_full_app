Uri buildPostAuthOnboardingRoute() {
  return Uri(
    path: '/parent/pin/verify',
    queryParameters: const {'next': '/parent/child/select'},
  );
}
