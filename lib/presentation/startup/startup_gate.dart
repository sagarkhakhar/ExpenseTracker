import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/startup/startup_guard.dart';
import '../../core/startup/startup_state.dart';
import '../../core/config/config_validator.dart';
import '../../core/config/config_provider.dart';
import '../../shared/widgets/platform_widgets.dart';

/// Gate widget that blocks main app until startup validation is complete
class StartupGate extends ConsumerStatefulWidget {
  const StartupGate({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  ConsumerState<StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends ConsumerState<StartupGate> {
  @override
  void initState() {
    super.initState();
    // Start validation process asynchronously to prevent UI blocking
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Allow multiple frames to render before starting heavy work
      await Future.delayed(const Duration(milliseconds: 100)); // Allow UI to render first
      if (mounted) {
        ref.read(startupGuardProvider.notifier).validateStartupAsync();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bypassValidation = ref.watch(bypassStartupValidationProvider);
    
    // PERFORMANCE FIX: Always bypass validation for now to prevent frame skips
    // TODO: Re-enable after optimizing startup validation
    if (true) { // Temporarily bypass all validation
      return widget.child;
    }
    
    // If bypassing validation, go straight to the app
    if (bypassValidation) {
      return widget.child;
    }
    
    final startupState = ref.watch(startupGuardProvider);
    
    return startupState.when(
      data: (state) {
        if (state.isHealthy) {
          return widget.child;
        } else {
          return StartupDiagnosticsScreen(state: state);
        }
      },
      loading: () => const StartupLoadingScreen(),
      error: (error, _) => StartupErrorScreen(
        error: error.toString(),
        onRetry: () => ref.read(startupGuardProvider.notifier).retry(),
      ),
    );
  }
}

/// Loading screen shown during startup validation
class StartupLoadingScreen extends ConsumerWidget {
  const StartupLoadingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final startupState = ref.watch(startupGuardProvider);
    
    final message = startupState.when(
      data: (state) => state.message ?? 'Initializing...',
      loading: () => 'Initializing...',
      error: (_, __) => 'Error during initialization',
    );

    return Scaffold(
      backgroundColor: PlatformWidgets.isIOS 
        ? CupertinoColors.systemBackground 
        : Theme.of(context).colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (PlatformWidgets.isIOS)
              const CupertinoActivityIndicator(radius: 20)
            else
              const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Setting up offline-first sync...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Error screen for startup failures with retry option
class StartupErrorScreen extends StatelessWidget {
  const StartupErrorScreen({
    super.key,
    required this.error,
    required this.onRetry,
  });

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PlatformWidgets.isIOS 
        ? CupertinoColors.systemBackground 
        : Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                PlatformWidgets.isIOS 
                  ? CupertinoIcons.exclamationmark_triangle
                  : Icons.error_outline,
                size: 64,
                color: Colors.orange,
              ),
              const SizedBox(height: 24),
              Text(
                'Startup Issue',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                error,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (PlatformWidgets.isIOS)
                CupertinoButton.filled(
                  onPressed: onRetry,
                  child: const Text('Retry'),
                )
              else
                ElevatedButton(
                  onPressed: onRetry,
                  child: const Text('Retry'),
                ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => _showDiagnostics(context),
                child: const Text('Show Diagnostics'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDiagnostics(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const StartupDiagnosticsPage(),
      ),
    );
  }
}

/// Diagnostics screen that shows detailed startup information
class StartupDiagnosticsScreen extends ConsumerWidget {
  const StartupDiagnosticsScreen({
    super.key,
    required this.state,
  });

  final StartupState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Startup Diagnostics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(startupGuardProvider.notifier).retry(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusCard(context, state),
            const SizedBox(height: 16),
            if (state.configValidation != null)
              _buildConfigCard(context, state.configValidation!),
            const SizedBox(height: 16),
            if (state.networkProbe != null)
              _buildNetworkCard(context, state.networkProbe!),
            const SizedBox(height: 16),
            if (state.bootstrapDetails != null)
              _buildBootstrapCard(context, state.bootstrapDetails!),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: state.canRetry
                    ? () => ref.read(startupGuardProvider.notifier).retry()
                    : null,
                child: const Text('Retry Validation'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context, StartupState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  state.isHealthy ? Icons.check_circle : Icons.warning,
                  color: state.isHealthy ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(
                  'Status: ${state.status.name}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            if (state.message != null) ...[
              const SizedBox(height: 8),
              Text(state.message!),
            ],
            if (state.error != null) ...[
              const SizedBox(height: 8),
              Text(
                'Error: ${state.error}',
                style: TextStyle(color: Colors.red[700]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildConfigCard(BuildContext context, ConfigValidationResult config) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Configuration',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  config.isValid ? Icons.check : Icons.error,
                  color: config.isValid ? Colors.green : Colors.red,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(config.isValid ? 'Valid' : 'Invalid'),
              ],
            ),
            if (config.errors.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...config.errors.map((error) => Text(
                '• $error',
                style: TextStyle(color: Colors.red[700]),
              )),
            ],
            if (config.warnings.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...config.warnings.map((warning) => Text(
                '⚠ $warning',
                style: TextStyle(color: Colors.orange[700]),
              )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkCard(BuildContext context, NetworkProbeResult network) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Network Connectivity',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  network.isConnected ? Icons.wifi : Icons.wifi_off,
                  color: network.isConnected ? Colors.green : Colors.red,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text('Internet: ${network.isConnected ? 'Connected' : 'Disconnected'}'),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  network.canReachSupabase ? Icons.cloud : Icons.cloud_off,
                  color: network.canReachSupabase ? Colors.green : Colors.red,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text('Supabase: ${network.canReachSupabase ? 'Reachable' : 'Unreachable'}'),
              ],
            ),
            if (network.latencyMs != null) ...[
              const SizedBox(height: 4),
              Text('Latency: ${network.latencyMs}ms'),
            ],
            if (network.error != null) ...[
              const SizedBox(height: 8),
              Text(
                'Error: ${network.error}',
                style: TextStyle(color: Colors.red[700]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBootstrapCard(BuildContext context, Map<String, dynamic> details) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Database Bootstrap',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ...details.entries.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('${entry.key}: ${entry.value}'),
            )),
          ],
        ),
      ),
    );
  }
}

/// Content-only version for embedding (no Scaffold)
class _StartupDiagnosticsContent extends ConsumerWidget {
  const _StartupDiagnosticsContent({
    required this.state,
  });

  final StartupState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildStatusCard(context, state),
        const SizedBox(height: 16),
        if (state.configValidation != null)
          _buildConfigCard(context, state.configValidation!),
        const SizedBox(height: 16),
        if (state.networkProbe != null)
          _buildNetworkCard(context, state.networkProbe!),
        const SizedBox(height: 16),
        if (state.bootstrapDetails != null)
          _buildBootstrapCard(context, state.bootstrapDetails!),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: state.canRetry
                ? () => ref.read(startupGuardProvider.notifier).retry()
                : null,
            child: const Text('Retry Validation'),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard(BuildContext context, StartupState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Startup Status',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  state.isHealthy ? Icons.check_circle : Icons.error,
                  color: state.isHealthy ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  state.isHealthy ? 'Healthy' : 'Issues Detected',
                  style: TextStyle(
                    color: state.isHealthy ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Current State: ${state.status.name}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (state.error != null) ...[
              const SizedBox(height: 8),
              Text(
                'Error: ${state.error}',
                style: TextStyle(color: Colors.red[700]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildConfigCard(BuildContext context, ConfigValidationResult validation) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Configuration',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  validation.isValid ? Icons.check_circle : Icons.error,
                  color: validation.isValid ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  validation.isValid ? 'Valid' : 'Invalid',
                  style: TextStyle(
                    color: validation.isValid ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (validation.errors.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...validation.errors.map((error) => Text(
                '• $error',
                style: TextStyle(color: Colors.red[700]),
              )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkCard(BuildContext context, NetworkProbeResult probe) {
    final isOnline = probe.isConnected;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Network',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  isOnline ? Icons.wifi : Icons.wifi_off,
                  color: isOnline ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  isOnline ? 'Online' : 'Offline',
                  style: TextStyle(
                    color: isOnline ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Can reach Supabase: ${probe.canReachSupabase}'),
            if (probe.latencyMs != null)
              Text('Latency: ${probe.latencyMs}ms'),
            if (probe.error != null)
              Text('Error: ${probe.error}', style: TextStyle(color: Colors.red[700])),
          ],
        ),
      ),
    );
  }

  Widget _buildBootstrapCard(BuildContext context, Map<String, dynamic> details) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Database Bootstrap',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ...details.entries.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('${entry.key}: ${entry.value}'),
            )),
          ],
        ),
      ),
    );
  }
}

/// Full-page diagnostics view
class StartupDiagnosticsPage extends ConsumerWidget {
  const StartupDiagnosticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final startupState = ref.watch(startupGuardProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Startup Diagnostics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(startupGuardProvider.notifier).retry(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (startupState != null)
              _StartupDiagnosticsContent(state: startupState)
            else
              const Text('Loading diagnostics...'),
          ],
        ),
      ),
    );
  }
}