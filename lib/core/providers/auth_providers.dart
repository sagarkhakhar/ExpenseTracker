import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../services/authentication_service.dart';
import '../services/data_migration_service.dart';

/// Authentication state enumeration
enum AuthenticationStatus {
  unauthenticated,
  authenticated,
  emailVerificationPending,
}

/// Authentication state model
class AuthenticationState {
  final AuthenticationStatus status;
  final User? user;
  final String? error;
  final bool isLoading;

  const AuthenticationState({
    required this.status,
    this.user,
    this.error,
    this.isLoading = false,
  });

  const AuthenticationState.unauthenticated({this.error})
      : status = AuthenticationStatus.unauthenticated,
        user = null,
        isLoading = false;

  const AuthenticationState.authenticated(User user)
      : status = AuthenticationStatus.authenticated,
        user = user,
        error = null,
        isLoading = false;

  const AuthenticationState.emailVerificationPending(User user)
      : status = AuthenticationStatus.emailVerificationPending,
        user = user,
        error = null,
        isLoading = false;

  const AuthenticationState.loading()
      : status = AuthenticationStatus.unauthenticated,
        user = null,
        error = null,
        isLoading = true;

  bool get isAuthenticated => status != AuthenticationStatus.unauthenticated;
  bool get needsEmailVerification => status == AuthenticationStatus.emailVerificationPending;
  bool get isFullyAuthenticated => status == AuthenticationStatus.authenticated;
  String? get userId => user?.id;

  AuthenticationState copyWith({
    AuthenticationStatus? status,
    User? user,
    String? error,
    bool? isLoading,
  }) {
    return AuthenticationState(
      status: status ?? this.status,
      user: user ?? this.user,
      error: error ?? this.error,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthenticationState &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          user == other.user &&
          error == other.error &&
          isLoading == other.isLoading;

  @override
  int get hashCode =>
      status.hashCode ^ user.hashCode ^ error.hashCode ^ isLoading.hashCode;

  @override
  String toString() {
    return 'AuthenticationState{status: $status, user: ${user?.id}, error: $error, isLoading: $isLoading}';
  }
}

/// Authentication notifier using Riverpod AsyncNotifier pattern
/// Manages authentication state and listens to Supabase auth changes
class AuthenticationNotifier extends AsyncNotifier<AuthenticationState> {
  late AuthenticationService _authService;
  late DataMigrationService _migrationService;

  @override
  Future<AuthenticationState> build() async {
    _authService = ref.read(authenticationServiceProvider);
    _migrationService = ref.read(dataMigrationServiceProvider);
    
    // Listen to authentication state changes
    _listenToAuthChanges();
    
    // Get initial authentication state
    return _getInitialAuthState();
  }

  /// Get initial authentication state from current session
  Future<AuthenticationState> _getInitialAuthState() async {
    try {
      // Get current session using Context7 pattern
      final currentSession = Supabase.instance.client.auth.currentSession;
      
      if (currentSession?.user != null) {
        final user = currentSession!.user;
        return user.emailConfirmedAt == null
            ? AuthenticationState.emailVerificationPending(user)
            : AuthenticationState.authenticated(user);
      }
      
      return const AuthenticationState.unauthenticated();
    } catch (e) {
      // Handle session recovery errors gracefully
      return AuthenticationState.unauthenticated(error: 'Session recovery failed: $e');
    }
  }

  /// Listen to Supabase authentication state changes using Context7 pattern
  void _listenToAuthChanges() {
    _authService.onAuthStateChange.listen(
      (authState) {
        final newState = _mapAuthStateToAppState(authState);
        // Update state without triggering loading
        state = AsyncValue.data(newState);
      },
      onError: (error) {
        state = AsyncValue.data(
          AuthenticationState.unauthenticated(error: error.toString()),
        );
      },
    );
  }

  /// Map Supabase AppAuthState to app AuthenticationState
  AuthenticationState _mapAuthStateToAppState(AppAuthState authState) {
    switch (authState.event) {
      case AuthChangeEvent.signedIn:
        if (authState.user != null) {
          // Trigger data migration for new user authentication
          _triggerDataMigrationIfNeeded(authState.user!.id);
          
          if (authState.user!.emailConfirmedAt == null) {
            return AuthenticationState.emailVerificationPending(authState.user!);
          } else {
            return AuthenticationState.authenticated(authState.user!);
          }
        }
        return const AuthenticationState.unauthenticated();
      
      case AuthChangeEvent.signedOut:
        return const AuthenticationState.unauthenticated();
      
      case AuthChangeEvent.tokenRefreshed:
        if (authState.user != null) {
          if (authState.user!.emailConfirmedAt == null) {
            return AuthenticationState.emailVerificationPending(authState.user!);
          } else {
            return AuthenticationState.authenticated(authState.user!);
          }
        }
        return const AuthenticationState.unauthenticated();
      
      case AuthChangeEvent.userUpdated:
        if (authState.user != null) {
          if (authState.user!.emailConfirmedAt == null) {
            return AuthenticationState.emailVerificationPending(authState.user!);
          } else {
            return AuthenticationState.authenticated(authState.user!);
          }
        }
        return const AuthenticationState.unauthenticated();
      
      case AuthChangeEvent.passwordRecovery:
        // Keep current state for password recovery
        return state.value ?? const AuthenticationState.unauthenticated();
      
      case AuthChangeEvent.userDeleted:
        return const AuthenticationState.unauthenticated();
      
      default:
        return state.value ?? const AuthenticationState.unauthenticated();
    }
  }


  /// Sign up with email and password
  Future<void> signUpWithPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    state = const AsyncValue.loading();
    
    final result = await _authService.signUpWithPassword(
      email: email,
      password: password,
      displayName: displayName,
    );
    
    result.when(
      success: (user) {
        // State will be updated by auth state change listener
        final newState = user.emailConfirmedAt == null
            ? AuthenticationState.emailVerificationPending(user)
            : AuthenticationState.authenticated(user);
        state = AsyncValue.data(newState);
      },
      failure: (exception) {
        state = AsyncValue.data(
          AuthenticationState.unauthenticated(error: exception.message),
        );
      },
      loading: (_) {
        state = const AsyncValue.loading();
      },
    );
  }

  /// Sign in with email and password
  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    
    final result = await _authService.signInWithPassword(
      email: email,
      password: password,
    );
    
    result.when(
      success: (user) {
        // State will be updated by auth state change listener
        final newState = user.emailConfirmedAt == null
            ? AuthenticationState.emailVerificationPending(user)
            : AuthenticationState.authenticated(user);
        state = AsyncValue.data(newState);
      },
      failure: (exception) {
        state = AsyncValue.data(
          AuthenticationState.unauthenticated(error: exception.message),
        );
      },
      loading: (_) {
        state = const AsyncValue.loading();
      },
    );
  }

  /// Reset password for email
  Future<void> resetPasswordForEmail(String email) async {
    final currentState = state.value ?? const AuthenticationState.unauthenticated();
    state = AsyncValue.data(currentState.copyWith(isLoading: true));
    
    final result = await _authService.resetPasswordForEmail(email);
    
    result.when(
      success: (_) {
        state = AsyncValue.data(currentState.copyWith(isLoading: false));
      },
      failure: (exception) {
        state = AsyncValue.data(
          currentState.copyWith(
            isLoading: false,
            error: exception.message,
          ),
        );
      },
      loading: (_) {
        state = AsyncValue.data(currentState.copyWith(isLoading: true));
      },
    );
  }

  /// Resend email confirmation
  Future<void> resendEmailConfirmation() async {
    final currentState = state.value;
    if (currentState == null) return;

    state = AsyncValue.data(currentState.copyWith(isLoading: true));
    
    final result = await _authService.resendEmailConfirmation();
    
    result.when(
      success: (_) {
        state = AsyncValue.data(currentState.copyWith(isLoading: false));
      },
      failure: (exception) {
        state = AsyncValue.data(
          currentState.copyWith(
            isLoading: false,
            error: exception.message,
          ),
        );
      },
      loading: (_) {
        state = AsyncValue.data(currentState.copyWith(isLoading: true));
      },
    );
  }

  /// Sign out current user
  Future<void> signOut() async {
    final currentState = state.value;
    if (currentState == null) return;

    state = AsyncValue.data(currentState.copyWith(isLoading: true));
    
    final result = await _authService.signOut();
    
    result.when(
      success: (_) {
        // State will be updated by auth state change listener
        state = const AsyncValue.data(AuthenticationState.unauthenticated());
      },
      failure: (exception) {
        state = AsyncValue.data(
          currentState.copyWith(
            isLoading: false,
            error: exception.message,
          ),
        );
      },
      loading: (_) {
        // Keep current state during loading
        state = AsyncValue.data(currentState.copyWith(isLoading: true));
      },
    );
  }

  /// Get current user ID for RLS policies
  String? get currentUserId {
    final currentState = state.value;
    return currentState?.userId;
  }

  /// Check if user is authenticated
  bool get isAuthenticated {
    final currentState = state.value;
    return currentState?.isAuthenticated ?? false;
  }


  /// Trigger data migration if needed for the authenticated user
  /// This runs in the background and doesn't block the UI
  void _triggerDataMigrationIfNeeded(String userId) {
    // Run migration in background without blocking auth state changes
    Future.microtask(() async {
      try {
        final needsMigration = await _migrationService.needsMigration(userId);
        
        if (needsMigration.isSuccess && needsMigration.data == true) {
          debugPrint('🔄 Starting background data migration for user $userId');
          
          final result = await _migrationService.performMigration(userId);
          
          result.fold(
            onSuccess: (migrationResult) {
              debugPrint('✅ Data migration completed: ${migrationResult.migratedItems} items migrated');
            },
            onFailure: (error) {
              debugPrint('❌ Data migration failed: ${error.message}');
              // Migration failure should not break authentication
              // The user can still use the app, and migration can be retried later
            },
          );
        }
      } catch (e) {
        debugPrint('❌ Error during data migration check: $e');
        // Don't break authentication flow on migration errors
      }
    });
  }
}

/// Provider for AuthenticationNotifier
final authenticationProvider = AsyncNotifierProvider<AuthenticationNotifier, AuthenticationState>(
  () => AuthenticationNotifier(),
);

/// Convenience provider for current user ID (for RLS policies)
final currentUserIdProvider = Provider<String?>((ref) {
  final authState = ref.watch(authenticationProvider);
  return authState.when(
    data: (state) => state.userId,
    loading: () => null,
    error: (_, __) => null,
  );
});

/// Convenience provider for authentication status
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authenticationProvider);
  return authState.when(
    data: (state) => state.isAuthenticated,
    loading: () => false,
    error: (_, __) => false,
  );
});

