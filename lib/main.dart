import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'package:study_circle/firebase_options.dart';
import 'package:study_circle/theme/app_theme.dart';
import 'package:study_circle/utils/logger.dart';
import 'package:study_circle/utils/constants.dart';
import 'package:study_circle/providers/theme_provider.dart';
import 'package:study_circle/providers/auth_provider.dart';
import 'package:study_circle/screens/auth/login_screen.dart';
import 'package:study_circle/screens/home/home_screen.dart';
import 'package:study_circle/screens/groups/create_group_screen.dart';
import 'package:study_circle/screens/groups/group_details_screen.dart';
import 'package:study_circle/models/study_group_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AppLogger.init();
  AppLogger.info('Starting StudyCircle application...');

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    AppLogger.info('Firebase initialized successfully');
  } catch (e, stackTrace) {
    AppLogger.error('Failed to initialize Firebase', e, stackTrace);
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()..init()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const AuthWrapper(),
            routes: {
              '/create-group': (context) => const CreateGroupScreen(),
              '/group-details': (context) {
                final groupId = ModalRoute.of(context)!.settings.arguments as String;
                return GroupDetailsScreen(groupId: groupId);
              },
              '/edit-group': (context) {
                final group = ModalRoute.of(context)!.settings.arguments as StudyGroupModel;
                return CreateGroupScreen(group: group);
              },
            },
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        // Show splash screen while initializing
        if (authProvider.status == AuthStatus.uninitialized) {
          return const SplashScreen();
        }

        // Navigate based on auth status
        if (authProvider.isAuthenticated && authProvider.userModel != null) {
          // User is authenticated - navigate to home
          return const HomeScreen();
        } else {
          // User is not authenticated - show login
          return const LoginScreen();
        }
      },
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.school, size: 100, color: Colors.white),
              const SizedBox(height: 20),
              Text(
                AppConstants.appName,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Find Your Study Circle',
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 40),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
