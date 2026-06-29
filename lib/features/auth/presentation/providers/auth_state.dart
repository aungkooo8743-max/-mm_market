class AuthState {
  final bool isLoading;
  final bool otpSent;
  final bool verified;
  final String? verificationId;
  final String? errorMessage;

  const AuthState({this.isLoading = false, this.otpSent = false, this.verified = false, this.verificationId, this.errorMessage});

  AuthState copyWith({bool? isLoading, bool? otpSent, bool? verified, String? verificationId, String? errorMessage, bool clearError = false}) => AuthState(isLoading: isLoading ?? this.isLoading, otpSent: otpSent ?? this.otpSent, verified: verified ?? this.verified, verificationId: verificationId ?? this.verificationId, errorMessage: clearError ? null : errorMessage);
}
