import 'package:equatable/equatable.dart';
import '../config/config_validator.dart';

/// States for the startup validation process
enum StartupStatus {
  idle,
  validatingConfig,
  probingAuth,
  bootstrapping,
  initializing, // Added for legacy data initialization
  healthy,
  error,
}

/// Startup validation state
class StartupState extends Equatable {
  const StartupState({
    required this.status,
    this.message,
    this.configValidation,
    this.networkProbe,
    this.bootstrapDetails,
    this.error,
  });

  final StartupStatus status;
  final String? message;
  final ConfigValidationResult? configValidation;
  final NetworkProbeResult? networkProbe;
  final Map<String, dynamic>? bootstrapDetails;
  final String? error;

  bool get isLoading => status == StartupStatus.validatingConfig ||
                       status == StartupStatus.probingAuth ||
                       status == StartupStatus.bootstrapping ||
                       status == StartupStatus.initializing;

  bool get canRetry => status == StartupStatus.error;
  bool get isHealthy => status == StartupStatus.healthy;
  bool get hasError => status == StartupStatus.error && error != null;

  @override
  List<Object?> get props => [
        status,
        message,
        configValidation,
        networkProbe,
        bootstrapDetails,
        error,
      ];

  StartupState copyWith({
    StartupStatus? status,
    String? message,
    ConfigValidationResult? configValidation,
    NetworkProbeResult? networkProbe,
    Map<String, dynamic>? bootstrapDetails,
    String? error,
  }) {
    return StartupState(
      status: status ?? this.status,
      message: message ?? this.message,
      configValidation: configValidation ?? this.configValidation,
      networkProbe: networkProbe ?? this.networkProbe,
      bootstrapDetails: bootstrapDetails ?? this.bootstrapDetails,
      error: error ?? this.error,
    );
  }

  /// Factory constructors for common states
  factory StartupState.idle() => const StartupState(
        status: StartupStatus.idle,
        message: 'Ready to start validation',
      );

  factory StartupState.validatingConfig() => const StartupState(
        status: StartupStatus.validatingConfig,
        message: 'Validating configuration...',
      );

  factory StartupState.probingAuth() => const StartupState(
        status: StartupStatus.probingAuth,
        message: 'Testing network connectivity...',
      );

  factory StartupState.bootstrapping() => const StartupState(
        status: StartupStatus.bootstrapping,
        message: 'Initializing database schema...',
      );

  factory StartupState.initializing() => const StartupState(
        status: StartupStatus.initializing,
        message: 'Initializing local data...',
      );

  factory StartupState.healthy({
    Map<String, dynamic>? details,
  }) =>
      StartupState(
        status: StartupStatus.healthy,
        message: 'System ready',
        bootstrapDetails: details,
      );

  factory StartupState.error(String errorMessage) => StartupState(
        status: StartupStatus.error,
        message: 'Startup failed',
        error: errorMessage,
      );

  @override
  String toString() => 'StartupState('
      'status: $status, '
      'message: $message, '
      'hasError: $hasError)';
}