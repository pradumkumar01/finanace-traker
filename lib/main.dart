import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'controllers/auth_controller.dart';
import 'controllers/finance_controller.dart';
import 'services/analytics_service.dart';
import 'package:firebase_analytics/firebase_analytics.dart'; // for FirebaseAnalyticsObserver type
import 'theme/app_theme.dart';
import 'screens/main_scaffold.dart';
import 'screens/auth/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  try {
    await GoogleSignIn.instance.initialize(
      serverClientId: dotenv.env['GOOGLE_WEB_CLIENT_ID'],
    );
  } catch (e) {
    debugPrint('Google Sign-In initialization failed: $e');
  }
  
  // Register analytics service first so it is available everywhere
  final analyticsService = Get.put(AnalyticsService());
  Get.put(AuthController());
  Get.put(FinanceController());
  
  runApp(FinanceApp(analyticsObserver: analyticsService.observer));
}

class FinanceApp extends StatelessWidget {
  final FirebaseAnalyticsObserver analyticsObserver;

  const FinanceApp({super.key, required this.analyticsObserver});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<FinanceController>(
      builder: (controller) {
        return GetMaterialApp(
          title: 'Finance Companion',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: controller.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          navigatorObservers: [analyticsObserver],
          home: const RootWrapper(),
        );
      },
    );
  }
}

class RootWrapper extends StatelessWidget {
  const RootWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final user = AuthController.to.firebaseUser.value;
      if (user != null) {
        return const MainScaffold();
      } else {
        return const LoginScreen();
      }
    });
  }
}

