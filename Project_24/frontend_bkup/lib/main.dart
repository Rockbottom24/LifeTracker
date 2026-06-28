import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/api/api_constants.dart';
import 'core/api/dio_client.dart';
import 'core/services/dashboard_service.dart';
import 'core/services/habit_service.dart';
import 'providers/dashboard_provider.dart';
import 'providers/habit_provider.dart';
import 'providers/theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final sharedPreferences = await SharedPreferences.getInstance();
  await sharedPreferences.setString(ApiConstants.baseUrlKey, ApiConstants.defaultBaseUrl);

  final apiClient = DioApiClient(sharedPreferences: sharedPreferences);
  await apiClient.initialize();

  final dashboardService = DashboardService(apiClient: apiClient);
  final habitService = HabitService(apiClient: apiClient);

  runApp(
    MultiProvider(
      providers: [
        Provider<SharedPreferences>.value(value: sharedPreferences),
        Provider<DioApiClient>.value(value: apiClient),
        Provider<DashboardService>.value(value: dashboardService),
        Provider<HabitService>.value(value: habitService),
        ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider(sharedPreferences)..load()),
        ChangeNotifierProvider<DashboardProvider>(create: (_) => DashboardProvider(dashboardService)),
        ChangeNotifierProvider<HabitProvider>(create: (_) => HabitProvider(habitService)),
      ],
      child: const LifeTrackerApp(),
    ),
  );
}
