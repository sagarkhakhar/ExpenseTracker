import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:expense_tracker/core/providers/auth_providers.dart';
import 'package:expense_tracker/core/services/authentication_service.dart';

import 'auth_providers_test.mocks.dart';
import '../services/authentication_service_test.mocks.dart';

// Generate mocks for testing
@GenerateMocks([AuthenticationService])
void main() {
  group('AuthenticationProviders', () {
    late MockAuthenticationService mockAuthService;
    late ProviderContainer container;

    setUp(() {
      mockAuthService = MockAuthenticationService();
      
      container = ProviderContainer(
        overrides: [
          authenticationServiceProvider.overrideWithValue(mockAuthService),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    group('AuthenticationState', () {
      test('should create unauthenticated state correctly', () {
        const state = AuthenticationState.unauthenticated();
        
        expect(state.status, AuthenticationStatus.unauthenticated);
        expect(state.user, isNull);
        expect(state.error, isNull);
        expect(state.isLoading, false);
        expect(state.isAuthenticated, false);
        expect(state.userId, isNull);
      });

      test('should create authenticated state correctly', () {
        final mockUser = MockUser();
        when(mockUser.id).thenReturn('test-user-id');
        
        final state = AuthenticationState.authenticated(mockUser);
        
        expect(state.status, AuthenticationStatus.authenticated);
        expect(state.user, equals(mockUser));
        expect(state.error, isNull);
        expect(state.isLoading, false);
        expect(state.isAuthenticated, true);
        expect(state.isFullyAuthenticated, true);
        expect(state.userId, 'test-user-id');
      });

      test('should create authenticated state correctly', () {
        final mockUser = MockUser();
        when(mockUser.id).thenReturn('test-user-id');
        
        final state = AuthenticationState.authenticated(mockUser);
        
        expect(state.status, AuthenticationStatus.authenticated);
        expect(state.user, equals(mockUser));
        expect(state.error, isNull);
        expect(state.isLoading, false);
        expect(state.isAuthenticated, true);
        expect(state.userId, 'test-user-id');
      });

      test('should create loading state correctly', () {
        const state = AuthenticationState.loading();
        
        expect(state.status, AuthenticationStatus.unauthenticated);
        expect(state.user, isNull);
        expect(state.error, isNull);
        expect(state.isLoading, true);
        expect(state.isAuthenticated, false);
      });

      test('should copy state with changes correctly', () {
        final mockUser = MockUser();
        const originalState = AuthenticationState.unauthenticated();
        
        final copiedState = originalState.copyWith(
          status: AuthenticationStatus.authenticated,
          user: mockUser,
          error: 'test error',
          isLoading: true,
        );
        
        expect(copiedState.status, AuthenticationStatus.authenticated);
        expect(copiedState.user, equals(mockUser));
        expect(copiedState.error, 'test error');
        expect(copiedState.isLoading, true);
      });

      test('should implement equality correctly', () {
        const state1 = AuthenticationState.unauthenticated();
        const state2 = AuthenticationState.unauthenticated();
        
        expect(state1, equals(state2));
        expect(state1.hashCode, equals(state2.hashCode));
      });

      test('should have proper string representation', () {
        const state = AuthenticationState.unauthenticated(error: 'test error');
        final stringRep = state.toString();
        
        expect(stringRep, contains('AuthenticationState'));
        expect(stringRep, contains('unauthenticated'));
        expect(stringRep, contains('test error'));
      });
    });

    group('currentUserIdProvider', () {
      test('should return user ID when authenticated', () async {
        final mockUser = MockUser();
        when(mockUser.id).thenReturn('test-user-id');
        
        container.read(authenticationProvider.notifier).state = 
            AsyncValue.data(AuthenticationState.authenticated(mockUser));

        final userId = container.read(currentUserIdProvider);
        expect(userId, equals('test-user-id'));
      });

      test('should return null when unauthenticated', () {
        container.read(authenticationProvider.notifier).state = 
            const AsyncValue.data(AuthenticationState.unauthenticated());

        final userId = container.read(currentUserIdProvider);
        expect(userId, isNull);
      });

      test('should return null when loading', () {
        container.read(authenticationProvider.notifier).state = 
            const AsyncValue.loading();

        final userId = container.read(currentUserIdProvider);
        expect(userId, isNull);
      });

      test('should return null when error', () {
        container.read(authenticationProvider.notifier).state = 
            const AsyncValue.error('error', StackTrace.empty);

        final userId = container.read(currentUserIdProvider);
        expect(userId, isNull);
      });
    });

    group('isAuthenticatedProvider', () {
      test('should return true when authenticated', () {
        final mockUser = MockUser();
        container.read(authenticationProvider.notifier).state = 
            AsyncValue.data(AuthenticationState.authenticated(mockUser));

        final isAuthenticated = container.read(isAuthenticatedProvider);
        expect(isAuthenticated, true);
      });

      test('should return false when unauthenticated', () {
        container.read(authenticationProvider.notifier).state = 
            const AsyncValue.data(AuthenticationState.unauthenticated());

        final isAuthenticated = container.read(isAuthenticatedProvider);
        expect(isAuthenticated, false);
      });

      test('should return false when loading', () {
        container.read(authenticationProvider.notifier).state = 
            const AsyncValue.loading();

        final isAuthenticated = container.read(isAuthenticatedProvider);
        expect(isAuthenticated, false);
      });

      test('should return false when error', () {
        container.read(authenticationProvider.notifier).state = 
            const AsyncValue.error('error', StackTrace.empty);

        final isAuthenticated = container.read(isAuthenticatedProvider);
        expect(isAuthenticated, false);
      });
    });

  });
}