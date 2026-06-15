import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/profile_provider.dart';
import 'providers/zen_provider.dart';
import 'providers/github_provider.dart';
import 'providers/ai_provider.dart';
import 'providers/project_provider.dart';
import 'providers/task_provider.dart';
import 'providers/snippet_provider.dart';
import 'providers/note_provider.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DevZenApp());
}

class DevZenApp extends StatelessWidget {
  const DevZenApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Core auth & identity
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => ZenProvider()),
        ChangeNotifierProvider(create: (_) => GitHubProvider()),
        ChangeNotifierProvider(create: (_) => AIProvider()),
        // Supporting providers
        ChangeNotifierProvider(create: (_) => ProjectProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => SnippetProvider()),
        ChangeNotifierProvider(create: (_) => NoteProvider()),
      ],
      child: MaterialApp(
        title: 'DevZen — Developer Identity Workspace',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const SplashScreen(),
      ),
    );
  }
}
