import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/services/api_service.dart';
import 'core/services/database_service.dart';
import 'core/services/sync_service.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await DatabaseService.instance.database;
  await ApiService.instance.refreshBaseUrl();
  
  runApp(const ProviderScope(child: EduMaxApp()));
}

/// EduMax App
/// 
/// The main application widget that manages authentication state
/// and routes to appropriate screens.
class EduMaxApp extends ConsumerStatefulWidget {
  const EduMaxApp({super.key});

  @override
  ConsumerState<EduMaxApp> createState() => _EduMaxAppState();
}

class _EduMaxAppState extends ConsumerState<EduMaxApp> {
  Timer? _syncTimer;

  @override
  void initState() {
    super.initState();
    _startAutoSync();
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }

  /// Start auto-sync timer - checks every hour for updates
  void _startAutoSync() {
    // Auto-sync every hour (3600000 ms)
    _syncTimer = Timer.periodic(
      const Duration(hours: 1),
      (_) => _performAutoSync(),
    );
  }

  /// Perform auto-sync when device is online
  Future<void> _performAutoSync() async {
    final authState = ref.read(authProvider);
    
    // Only sync if user is authenticated
    if (authState.user != null) {
      final syncService = SyncService.instance;
      
      // Check if online and perform sync
      if (await syncService.isOnline()) {
        await syncService.sync();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EduMax System',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF667eea),
        ),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
    );
  }
}

/// Auth Wrapper
/// 
/// Watches authentication state and routes to either
/// login screen or home screen accordingly.
class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    // Show loading while checking auth status
    if (authState.isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading...'),
            ],
          ),
        ),
      );
    }

    // Route based on auth status
    if (authState.user != null) {
      return const HomeScreen();
    }

    return const LoginScreen();
  }
}
