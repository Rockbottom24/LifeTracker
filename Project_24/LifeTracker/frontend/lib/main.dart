import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'local/local_cache_store.dart';
import 'local/offline_data_store.dart';
import 'navigation/auth_gate.dart';
import 'providers/auth_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/expense_provider.dart';
import 'providers/food_provider.dart';
import 'providers/habit_provider.dart';
import 'providers/learning_provider.dart';
import 'providers/meal_provider.dart';
import 'repositories/dashboard_repository.dart';
import 'repositories/habit_repository.dart';
import 'repositories/learning_repository.dart';
import 'services/api_client.dart';
import 'services/api_constants.dart';
import 'services/auth_service.dart';
import 'services/dashboard_service.dart';
import 'services/expense_service.dart';
import 'services/food_service.dart';
import 'services/habit_service.dart';
import 'services/learning_service.dart';
import 'services/meal_service.dart';
import 'services/nutrition_service.dart';
import 'services/notification_service.dart';
import 'sync/sync_engine.dart';
import 'theme/app_style.dart';
import 'theme/app_theme.dart';
import 'theme/theme_provider.dart';

Future<void> main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      debugPrint('FlutterError: ${details.exceptionAsString()}');
      if (details.stack != null) {
        debugPrint(details.stack.toString());
      }
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      debugPrint('Unhandled platform error: $error');
      debugPrint(stack.toString());
      return true;
    };
    ErrorWidget.builder = (details) {
      return Material(
        color: Colors.transparent,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Something went wrong while loading the app.',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    };

    final sharedPreferences = await SharedPreferences.getInstance();
    final storedBaseUrl = sharedPreferences.getString(ApiConstants.baseUrlKey);
    if (storedBaseUrl == null ||
        storedBaseUrl.isEmpty ||
        ApiConstants.shouldResetLegacyBaseUrl(storedBaseUrl)) {
      await sharedPreferences.setString(ApiConstants.baseUrlKey, ApiConstants.defaultBaseUrl);
    }

    final cache = LocalCacheStore.instance;
    await cache.init();

    final offlineStore = OfflineDataStore(cache);
    await offlineStore.ensureMigrated();

    final apiClient = DioApiClient(sharedPreferences: sharedPreferences);
    await apiClient.initialize();

    final authService = AuthService(apiClient: apiClient);

    final habitRepository = HabitRepository(offlineStore);
    final learningRepository = LearningRepository(offlineStore);
    final dashboardRepository = DashboardRepository(cache, offlineStore);

    final syncEngine = SyncEngine(
      apiClient: apiClient,
      offlineStore: offlineStore,
      habitRepository: habitRepository,
      learningRepository: learningRepository,
      dashboardRepository: dashboardRepository,
      cache: cache,
    );

    final habitService = HabitService(
      apiClient: apiClient,
      cache: cache,
      repository: habitRepository,
      syncEngine: syncEngine,
    );
    final dashboardService = DashboardService(
      repository: dashboardRepository,
      syncEngine: syncEngine,
    );
    final learningService = LearningService(
      apiClient: apiClient,
      cache: cache,
      repository: learningRepository,
      syncEngine: syncEngine,
    );
    final expenseService = ExpenseService(apiClient: apiClient);
    final foodService = FoodService(apiClient: apiClient);
    final mealService = MealService(apiClient: apiClient);
    final nutritionService = NutritionService(apiClient: apiClient);

    final authProvider = AuthProvider(
      sharedPreferences: sharedPreferences,
      authService: authService,
      apiClient: apiClient,
    );

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider(sharedPreferences)..load()),
          ChangeNotifierProvider.value(value: authProvider),
          ChangeNotifierProvider(create: (_) => DashboardProvider(dashboardService, cache)),
          ChangeNotifierProvider(create: (_) => HabitProvider(habitService, cache)),
          ChangeNotifierProvider(create: (_) => LearningProvider(learningService, cache)),
          ChangeNotifierProvider(create: (_) => ExpenseProvider(expenseService)),
          ChangeNotifierProvider(create: (_) => FoodProvider(foodService)),
          ChangeNotifierProvider(create: (_) => MealProvider(mealService, nutritionService)),
        ],
        child: LifeTrackerApp(apiClient: apiClient, syncEngine: syncEngine, authProvider: authProvider),
      ),
    );

    await authProvider.initialize();
  }, (error, stack) {
    debugPrint('Fatal startup error: $error');
    debugPrint(stack.toString());
  });
}

class LifeTrackerApp extends StatefulWidget {
  const LifeTrackerApp({
    required this.apiClient,
    required this.syncEngine,
    required this.authProvider,
    super.key,
  });

  final DioApiClient apiClient;
  final SyncEngine syncEngine;
  final AuthProvider authProvider;

  @override
  State<LifeTrackerApp> createState() => _LifeTrackerAppState();
}

class _LifeTrackerAppState extends State<LifeTrackerApp> {
  bool _notificationsStarted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startDeferredInitialization());
  }

  Future<void> _startDeferredInitialization() async {
    if (_notificationsStarted) return;
    _notificationsStarted = true;
    await NotificationService().initialize();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final auth = context.watch<AuthProvider>();
    final style = themeProvider.style;

    return MaterialApp(
      title: 'LifeTracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(style: style, houseKey: auth.houseKey),
      darkTheme: AppTheme.darkTheme(style: style, houseKey: auth.houseKey),
      themeMode: switch (style) {
        AppStyle.classic => ThemeMode.light,
        AppStyle.fantasy => ThemeMode.dark,
        AppStyle.system => ThemeMode.system,
      },
      home: AuthGate(
        apiClient: widget.apiClient,
        syncEngine: widget.syncEngine,
      ),
    );
  }
}
