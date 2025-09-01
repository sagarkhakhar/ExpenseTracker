import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:expense_tracker/core/services/authentication_service.dart';
import 'package:expense_tracker/core/errors/exceptions.dart';

import 'authentication_service_test.mocks.dart';

// Generate mocks for testing
@GenerateMocks([
  SupabaseClient,
  GoTrueClient,
  User,
  Session,
  AuthResponse,
])
void main() {
  group('AuthenticationService', () {
    late MockSupabaseClient mockSupabaseClient;
    late MockGoTrueClient mockAuth;
    late MockUser mockUser;
    late MockSession mockSession;
    late MockAuthResponse mockAuthResponse;
    late AuthenticationService authService;

    setUp(() {
      mockSupabaseClient = MockSupabaseClient();
      mockAuth = MockGoTrueClient();
      mockUser = MockUser();
      mockSession = MockSession();
      mockAuthResponse = MockAuthResponse();

      // Setup mock client to return mock auth
      when(mockSupabaseClient.auth).thenReturn(mockAuth);

      authService = AuthenticationService(supabaseClient: mockSupabaseClient);
    });

    group('signUpWithPassword', () {
      test('should return success when sign-up succeeds', () async {
        // Arrange
        when(mockAuthResponse.user).thenReturn(mockUser);
        when(mockUser.id).thenReturn('test-user-id');
        when(mockUser.email).thenReturn('test@example.com');
        when(mockAuth.signUp(
          email: anyNamed('email'),
          password: anyNamed('password'),
          data: anyNamed('data'),
        )).thenAnswer((_) async => mockAuthResponse);

        // Act
        final result = await authService.signUpWithPassword(
          email: 'test@example.com',
          password: 'password123',
        );

        // Assert
        expect(result.isSuccess, true);
        expect(result.valueOrNull, equals(mockUser));
        verify(mockAuth.signUp(
          email: 'test@example.com',
          password: 'password123',
          data: null,
        )).called(1);
      });

      test('should return failure when sign-up returns no user', () async {
        // Arrange
        when(mockAuthResponse.user).thenReturn(null);
        when(mockAuth.signUp(
          email: anyNamed('email'),
          password: anyNamed('password'),
          data: anyNamed('data'),
        )).thenAnswer((_) async => mockAuthResponse);

        // Act
        final result = await authService.signUpWithPassword(
          email: 'test@example.com',
          password: 'password123',
        );

        // Assert
        expect(result.isFailure, true);
        expect(result.exceptionOrNull, isA<AppException>());
        expect(result.exceptionOrNull!.message, contains('No user returned'));
      });

      test('should return failure when AuthException is thrown', () async {
        // Arrange
        const authException = AuthException('Email already registered');
        when(mockAuth.signUp(
          email: anyNamed('email'),
          password: anyNamed('password'),
          data: anyNamed('data'),
        )).thenThrow(authException);

        // Act
        final result = await authService.signUpWithPassword(
          email: 'test@example.com',
          password: 'password123',
        );

        // Assert
        expect(result.isFailure, true);
        expect(result.exceptionOrNull, isA<AppException>());
        expect(result.exceptionOrNull!.message, contains('An account with this email already exists'));
      });
    });

    group('signInWithPassword', () {
      test('should return success when sign-in succeeds', () async {
        // Arrange
        when(mockAuthResponse.user).thenReturn(mockUser);
        when(mockUser.id).thenReturn('test-user-id');
        when(mockUser.email).thenReturn('test@example.com');
        when(mockAuth.signInWithPassword(
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenAnswer((_) async => mockAuthResponse);

        // Act
        final result = await authService.signInWithPassword(
          email: 'test@example.com',
          password: 'password123',
        );

        // Assert
        expect(result.isSuccess, true);
        expect(result.valueOrNull, equals(mockUser));
        verify(mockAuth.signInWithPassword(
          email: 'test@example.com',
          password: 'password123',
        )).called(1);
      });

      test('should return failure when AuthException is thrown', () async {
        // Arrange
        const authException = AuthException('Invalid login credentials');
        when(mockAuth.signInWithPassword(
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenThrow(authException);

        // Act
        final result = await authService.signInWithPassword(
          email: 'test@example.com',
          password: 'password123',
        );

        // Assert
        expect(result.isFailure, true);
        expect(result.exceptionOrNull, isA<AppException>());
        expect(result.exceptionOrNull!.message, contains('Invalid email or password'));
      });
    });

    group('resetPasswordForEmail', () {
      test('should return success when password reset succeeds', () async {
        // Arrange
        when(mockAuth.resetPasswordForEmail(any))
            .thenAnswer((_) async {});

        // Act
        final result = await authService.resetPasswordForEmail('test@example.com');

        // Assert
        expect(result.isSuccess, true);
        verify(mockAuth.resetPasswordForEmail('test@example.com')).called(1);
      });

      test('should return failure when AuthException is thrown', () async {
        // Arrange
        const authException = AuthException('User not found');
        when(mockAuth.resetPasswordForEmail(any))
            .thenThrow(authException);

        // Act
        final result = await authService.resetPasswordForEmail('test@example.com');

        // Assert
        expect(result.isFailure, true);
        expect(result.exceptionOrNull, isA<AppException>());
        expect(result.exceptionOrNull!.message, contains('No account found with this email'));
      });
    });

    group('getCurrentUser', () {
      test('should return current user when user is authenticated', () {
        // Arrange
        when(mockAuth.currentUser).thenReturn(mockUser);

        // Act
        final result = authService.getCurrentUser();

        // Assert
        expect(result, equals(mockUser));
        verify(mockAuth.currentUser).called(1);
      });

      test('should return null when no user is authenticated', () {
        // Arrange
        when(mockAuth.currentUser).thenReturn(null);

        // Act
        final result = authService.getCurrentUser();

        // Assert
        expect(result, isNull);
      });
    });

    group('getCurrentSession', () {
      test('should return current session when session exists', () {
        // Arrange
        when(mockAuth.currentSession).thenReturn(mockSession);

        // Act
        final result = authService.getCurrentSession();

        // Assert
        expect(result, equals(mockSession));
        verify(mockAuth.currentSession).called(1);
      });

      test('should return null when no session exists', () {
        // Arrange
        when(mockAuth.currentSession).thenReturn(null);

        // Act
        final result = authService.getCurrentSession();

        // Assert
        expect(result, isNull);
      });
    });

    group('signOut', () {
      test('should return success when sign out succeeds', () async {
        // Arrange
        when(mockAuth.signOut()).thenAnswer((_) async {});

        // Act
        final result = await authService.signOut();

        // Assert
        expect(result.isSuccess, true);
        verify(mockAuth.signOut()).called(1);
      });

      test('should return failure when AuthException is thrown', () async {
        // Arrange
        const authException = AuthException('Sign out failed');
        when(mockAuth.signOut()).thenThrow(authException);

        // Act
        final result = await authService.signOut();

        // Assert
        expect(result.isFailure, true);
        expect(result.exceptionOrNull, isA<AppException>());
        expect(result.exceptionOrNull!.message, contains('Sign out failed'));
      });

      test('should return failure when generic exception is thrown', () async {
        // Arrange
        when(mockAuth.signOut()).thenThrow(Exception('Network error'));

        // Act
        final result = await authService.signOut();

        // Assert
        expect(result.isFailure, true);
        expect(result.exceptionOrNull, isA<AppException>());
        expect(result.exceptionOrNull!.message, contains('Network error'));
      });
    });

    group('isAuthenticated', () {
      test('should return true when user is authenticated', () {
        // Arrange
        when(mockAuth.currentUser).thenReturn(mockUser);

        // Act
        final result = authService.isAuthenticated;

        // Assert
        expect(result, true);
      });

      test('should return false when no user is authenticated', () {
        // Arrange
        when(mockAuth.currentUser).thenReturn(null);

        // Act
        final result = authService.isAuthenticated;

        // Assert
        expect(result, false);
      });
    });


    group('currentUserId', () {
      test('should return user ID when user is authenticated', () {
        // Arrange
        const userId = 'test-user-id';
        when(mockAuth.currentUser).thenReturn(mockUser);
        when(mockUser.id).thenReturn(userId);

        // Act
        final result = authService.currentUserId;

        // Assert
        expect(result, equals(userId));
      });

      test('should return null when no user is authenticated', () {
        // Arrange
        when(mockAuth.currentUser).thenReturn(null);

        // Act
        final result = authService.currentUserId;

        // Assert
        expect(result, isNull);
      });
    });

    group('AppAuthState', () {
      test('should create AppAuthState with correct properties', () {
        // Arrange
        const event = AuthChangeEvent.signedIn;
        
        // Act
        final authState = AppAuthState(
          event: event,
          session: mockSession,
          user: mockUser,
        );

        // Assert
        expect(authState.event, equals(event));
        expect(authState.session, equals(mockSession));
        expect(authState.user, equals(mockUser));
      });

      test('should determine isAuthenticated correctly', () {
        // Arrange & Act
        final authenticatedState = AppAuthState(
          event: AuthChangeEvent.signedIn,
          user: mockUser,
        );
        const unauthenticatedState = AppAuthState(
          event: AuthChangeEvent.signedOut,
        );

        // Assert
        expect(authenticatedState.isAuthenticated, true);
        expect(unauthenticatedState.isAuthenticated, false);
      });


      test('should return userId correctly', () {
        // Arrange
        const userId = 'test-user-id';
        when(mockUser.id).thenReturn(userId);
        
        // Act
        final authState = AppAuthState(
          event: AuthChangeEvent.signedIn,
          user: mockUser,
        );

        // Assert
        expect(authState.userId, equals(userId));
      });

      test('should implement equality correctly', () {
        // Arrange
        final state1 = AppAuthState(
          event: AuthChangeEvent.signedIn,
          user: mockUser,
          session: mockSession,
        );
        final state2 = AppAuthState(
          event: AuthChangeEvent.signedIn,
          user: mockUser,
          session: mockSession,
        );

        // Act & Assert
        expect(state1, equals(state2));
        expect(state1.hashCode, equals(state2.hashCode));
      });

      test('should have proper string representation', () {
        // Arrange
        final authState = AppAuthState(
          event: AuthChangeEvent.signedIn,
          user: mockUser,
        );

        // Act
        final stringRep = authState.toString();

        // Assert
        expect(stringRep, contains('AppAuthState'));
        expect(stringRep, contains('signedIn'));
        expect(stringRep, contains('isAuthenticated: true'));
      });
    });
  });
}