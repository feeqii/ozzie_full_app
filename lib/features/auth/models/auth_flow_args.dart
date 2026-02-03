class AuthFlowArgs {
  const AuthFlowArgs({
    required this.email,
    required this.isSignUp,
    this.displayName,
  });

  final String email;
  final bool isSignUp;
  final String? displayName;
}
