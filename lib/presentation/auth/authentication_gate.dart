import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/auth_providers.dart';
import '../../features/auth/presentation/views/auth_main_screen.dart';
import '../../features/auth/presentation/views/email_verification_screen.dart';

/// Gate widget that shows authentication screens for unauthenticated users
/// and the main app for authenticated users
class AuthenticationGate extends ConsumerWidget {
  const AuthenticationGate({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authenticationProvider);
    
    return authState.when(
      data: (state) {
        if (state.isFullyAuthenticated) {
          return child;
        } else if (state.needsEmailVerification) {
          return const EmailVerificationScreen();
        } else {
          // Show authentication screens for unauthenticated users
          return const AuthMainScreen();
        }
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'Authentication Error',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(authenticationProvider);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}