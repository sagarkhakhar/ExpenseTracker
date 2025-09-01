import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../types/result.dart';
import '../errors/exceptions.dart';

/// Authentication service for managing email/password authentication
/// 
/// Follows Context7 Supabase patterns for session management and state handling
class AuthenticationService {
  final SupabaseClient _supabase;

  AuthenticationService({
    required SupabaseClient supabaseClient,
  }) : _supabase = supabaseClient;


  /// Get current authenticated user
  /// Returns null if no user is authenticated
  User? getCurrentUser() {
    return _supabase.auth.currentUser;
  }

  /// Get current session
  /// Returns null if no session exists
  Session? getCurrentSession() {
    return _supabase.auth.currentSession;
  }

  /// Sign up with email and password using Supabase email authentication
  /// Returns the authenticated user or failure
  Future<Result<User>> signUpWithPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: displayName != null ? {'display_name': displayName} : null,
        emailRedirectTo: 'io.expensetracker://auth/callback',
      );
      
      if (response.user != null) {
        return Result.success(response.user!);
      } else {
        return Result.failure(
          AppException.create(
            message: 'Sign up failed: No user returned',
            errorCode: 'AUTH_SIGNUP_NO_USER',
          ),
        );
      }
    } on AuthException catch (e) {
      return Result.failure(
        AppException.create(
          message: _getReadableAuthError(e),
          errorCode: 'AUTH_SIGNUP_ERROR',
          technicalDetails: e.toString(),
        ),
      );
    } catch (e) {
      return Result.failure(
        AppException.create(
          message: 'Sign up failed: $e',
          errorCode: 'AUTH_SIGNUP_UNKNOWN_ERROR',
          technicalDetails: e.toString(),
        ),
      );
    }
  }

  /// Sign in with email and password using Supabase email authentication
  /// Returns the authenticated user or failure
  Future<Result<User>> signInWithPassword({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.user != null) {
        return Result.success(response.user!);
      } else {
        return Result.failure(
          AppException.create(
            message: 'Sign in failed: No user returned',
            errorCode: 'AUTH_SIGNIN_NO_USER',
          ),
        );
      }
    } on AuthException catch (e) {
      return Result.failure(
        AppException.create(
          message: _getReadableAuthError(e),
          errorCode: 'AUTH_SIGNIN_ERROR',
          technicalDetails: e.toString(),
        ),
      );
    } catch (e) {
      return Result.failure(
        AppException.create(
          message: 'Sign in failed: $e',
          errorCode: 'AUTH_SIGNIN_UNKNOWN_ERROR',
          technicalDetails: e.toString(),
        ),
      );
    }
  }

  /// Reset password for email using Supabase password recovery
  /// Returns success or failure
  Future<Result<void>> resetPasswordForEmail(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
      return const Result.success(null);
    } on AuthException catch (e) {
      return Result.failure(
        AppException.create(
          message: _getReadableAuthError(e),
          errorCode: 'AUTH_RESET_PASSWORD_ERROR',
          technicalDetails: e.toString(),
        ),
      );
    } catch (e) {
      return Result.failure(
        AppException.create(
          message: 'Password reset failed: $e',
          errorCode: 'AUTH_RESET_PASSWORD_UNKNOWN_ERROR',
          technicalDetails: e.toString(),
        ),
      );
    }
  }

  /// Resend email confirmation for the current user
  /// Returns success or failure
  Future<Result<void>> resendEmailConfirmation() async {
    try {
      final user = getCurrentUser();
      if (user?.email == null) {
        return Result.failure(
          AppException.create(
            message: 'No user email found for resending confirmation',
            errorCode: 'AUTH_NO_USER_EMAIL',
          ),
        );
      }

      await _supabase.auth.resend(
        type: OtpType.signup,
        email: user!.email!,
        emailRedirectTo: 'io.expensetracker://auth/callback',
      );
      
      return const Result.success(null);
    } on AuthException catch (e) {
      return Result.failure(
        AppException.create(
          message: _getReadableAuthError(e),
          errorCode: 'AUTH_RESEND_CONFIRMATION_ERROR',
          technicalDetails: e.toString(),
        ),
      );
    } catch (e) {
      return Result.failure(
        AppException.create(
          message: 'Resend confirmation failed: $e',
          errorCode: 'AUTH_RESEND_CONFIRMATION_UNKNOWN_ERROR',
          technicalDetails: e.toString(),
        ),
      );
    }
  }

  /// Sign out current user and clear session
  Future<Result<void>> signOut() async {
    try {
      await _supabase.auth.signOut();
      return const Result.success(null);
    } on AuthException catch (e) {
      return Result.failure(
        AppException.create(
          message: 'Sign out failed: ${e.message}',
          errorCode: 'AUTH_SIGNOUT_ERROR',
          technicalDetails: e.toString(),
        ),
      );
    } catch (e) {
      return Result.failure(
        AppException.create(
          message: 'Sign out failed: $e',
          errorCode: 'AUTH_SIGNOUT_UNKNOWN_ERROR',
          technicalDetails: e.toString(),
        ),
      );
    }
  }

  /// Check if user is currently authenticated
  bool get isAuthenticated => getCurrentUser() != null;

  /// Check if current user needs email confirmation
  bool get needsEmailConfirmation {
    final user = getCurrentUser();
    return user != null && user.emailConfirmedAt == null;
  }

  /// Get current user ID for RLS policies
  /// Returns null if no user is authenticated
  String? get currentUserId => getCurrentUser()?.id;

  /// Stream of authentication state changes
  /// Use Context7 pattern for listening to auth events
  Stream<AppAuthState> get onAuthStateChange {
    return _supabase.auth.onAuthStateChange.map((data) {
      final event = data.event;
      final session = data.session;
      final user = session?.user;

      return AppAuthState(
        event: event,
        session: session,
        user: user,
      );
    });
  }

  /// Convert Supabase AuthException to user-friendly error messages
  String _getReadableAuthError(AuthException e) {
    switch (e.message.toLowerCase()) {
      case String msg when msg.contains('email already registered'):
        return 'An account with this email already exists. Please try signing in instead.';
      case String msg when msg.contains('invalid login credentials'):
        return 'Invalid email or password. Please check your credentials and try again.';
      case String msg when msg.contains('email not confirmed'):
        return 'Please check your email and click the confirmation link before signing in.';
      case String msg when msg.contains('password should be at least'):
        return 'Password must be at least 8 characters long with uppercase, lowercase, and numbers.';
      case String msg when msg.contains('invalid email'):
        return 'Please enter a valid email address.';
      case String msg when msg.contains('signup is disabled'):
        return 'Account registration is currently disabled. Please contact support.';
      case String msg when msg.contains('too many requests'):
        return 'Too many attempts. Please wait a few minutes before trying again.';
      case String msg when msg.contains('network'):
        return 'Network error. Please check your connection and try again.';
      case String msg when msg.contains('user not found'):
        return 'No account found with this email address.';
      default:
        return e.message ?? 'An authentication error occurred. Please try again.';
    }
  }
}

/// Authentication state wrapper following Context7 patterns
class AppAuthState {
  final AuthChangeEvent event;
  final Session? session;
  final User? user;

  const AppAuthState({
    required this.event,
    this.session,
    this.user,
  });

  bool get isAuthenticated => user != null;
  String? get userId => user?.id;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppAuthState &&
          runtimeType == other.runtimeType &&
          event == other.event &&
          session == other.session &&
          user == other.user;

  @override
  int get hashCode => event.hashCode ^ session.hashCode ^ user.hashCode;

  @override
  String toString() {
    return 'AppAuthState{event: $event, isAuthenticated: $isAuthenticated}';
  }
}

/// Provider for AuthenticationService
final authenticationServiceProvider = Provider<AuthenticationService>((ref) {
  return AuthenticationService(
    supabaseClient: Supabase.instance.client,
  );
});