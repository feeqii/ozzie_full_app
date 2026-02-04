@Deprecated('OTP flow removed. This model is retained temporarily for cleanup.')
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
