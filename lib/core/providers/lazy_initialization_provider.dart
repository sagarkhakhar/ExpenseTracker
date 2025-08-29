import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

/// Provider that controls when heavy initialization should happen
/// This prevents immediate initialization during app startup
final shouldInitializeHeavyResourcesProvider = StateProvider<bool>((ref) => false);

/// Provider that tracks if the app has completed initial UI rendering
final appInitialRenderCompleteProvider = StateProvider<bool>((ref) => false);

/// Mixin to add lazy initialization behavior to notifiers
mixin LazyInitializationMixin<T> on AutoDisposeAsyncNotifier<T> {
  
  /// Override build to check if heavy resources should be initialized
  @override
  Future<T> build() async {
    // Wait for initial render to complete before doing heavy work
    final renderComplete = ref.read(appInitialRenderCompleteProvider);
    
    if (!renderComplete) {
      // Add a delay to allow UI to render first
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Mark render as complete for future providers
      ref.read(appInitialRenderCompleteProvider.notifier).state = true;
    }
    
    return buildLazy();
  }
  
  /// Implement this method instead of build() in your notifiers
  Future<T> buildLazy();
}

/// Utility to mark when the app UI has completed initial rendering
void markAppRenderComplete(WidgetRef ref) {
  if (!ref.read(appInitialRenderCompleteProvider)) {
    debugPrint('🎨 App initial render complete - enabling lazy loading');
    ref.read(appInitialRenderCompleteProvider.notifier).state = true;
  }
}