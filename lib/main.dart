import 'package:elang_dashboard_new_ui/services/fcm_service.dart';
import 'package:elang_dashboard_new_ui/auth_provider.dart';
import 'package:elang_dashboard_new_ui/login.dart';
import 'package:elang_dashboard_new_ui/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final authProvider = AuthProvider();
  final packageInfo = await PackageInfo.fromPlatform();

  await authProvider.initializeAuth();
  await FCMService.initialize();
  await dotenv.load(fileName: '.env');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        Provider<String>.value(value: packageInfo.version),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Verify authentication when app is resumed
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      authProvider.checkAndRevalidateToken();
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          // Only redirect to Homepage if the user is properly logged in
          if (authProvider.isLoggedIn() && authProvider.token.isNotEmpty) {
            return const Homepage();
          }
          // Default to the login page
          return const LoginPage();
        },
      ),
    );
  }
}
