enum AppStartupStatus { initial, ready, error }

class AppStartupState {
  const AppStartupState._({required this.status, this.message});

  final AppStartupStatus status;
  final String? message;

  const AppStartupState.initial() : this._(status: AppStartupStatus.initial);
  const AppStartupState.ready() : this._(status: AppStartupStatus.ready);
  const AppStartupState.error(String message)
      : this._(status: AppStartupStatus.error, message: message);

  @override
  bool operator ==(Object other) {
    return other is AppStartupState &&
        other.status == status &&
        other.message == message;
  }

  @override
  int get hashCode => Object.hash(status, message);
}
