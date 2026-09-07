import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/dashboard_response.dart';
import '../navigation/add_habit_page_route.dart';
import '../navigation/app_navigator.dart';
import '../providers/local_auth_provider.dart';
import '../providers/dashboard_provider.dart';
import '../providers/habit_provider.dart';
import '../providers/learning_provider.dart';
import '../theme/app_spacing.dart';
import '../theme/house_theme.dart';
import '../utils/dashboard_view_data_mapper.dart';
import '../widgets/offline_sync_banner.dart';
import '../widgets/chronicle_card.dart';
import '../widgets/dashboard/dashboard_hero_card.dart';
import '../widgets/dashboard/dashboard_skeleton.dart';
import '../widgets/dashboard/progress_ring_card.dart';
import '../widgets/dashboard/stats_grid.dart';
import '../widgets/dashboard/todays_habits_section.dart';
import '../widgets/dashboard/todays_learning_section.dart';
import '../widgets/dashboard/upcoming_reminder_card.dart';
import '../widgets/dashboard/weekly_progress_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/responsive_form_container.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    await Future.wait([
      context.read<DashboardProvider>().loadDashboard(),
      context.read<HabitProvider>().loadHabits(),
      context.read<LearningProvider>().loadSessions(),
    ]);
  }

  Future<void> _completeHabit(int habitId) async {
    final auth = context.read<LocalAuthProvider>();
    final house = auth.house;
    await context.read<HabitProvider>().completeHabit(habitId);
    if (mounted) {
      await context.read<DashboardProvider>().loadDashboard();
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Text(house.sigil, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Quest Sealed for House ${house.name}! "${house.motto}"',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: house.bannerGradient[1],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: house.accent.withValues(alpha: 0.6)),
          ),
          duration: const Duration(milliseconds: 2200),
        ),
      );
    }
  }

  Future<void> _undoHabit(int habitId) async {
    await context.read<HabitProvider>().undoHabit(habitId);
    if (mounted) {
      await context.read<DashboardProvider>().loadDashboard();
    }
  }

  void _openHabitDetails(int habitId) {
    AppNavigator.openHabitDetails(context, habitId);
  }

  void _openCreateHabit() {
    Navigator.of(context).push(
      AddHabitPageRoute(settings: const RouteSettings(name: '/add-habit')),
    );
  }

  void _openProfile() {
    AppNavigator.openProfile(context);
  }

  void _openLearningDetails(int sessionId) {
    AppNavigator.openLearningDetails(context, sessionId);
  }

  Future<void> _quickStartLearning(int sessionId) async {
    await context.read<LearningProvider>().startSession(sessionId);
    if (mounted) _openLearningDetails(sessionId);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final dashboardProvider = context.watch<DashboardProvider>();
    final habitProvider = context.watch<HabitProvider>();
    final learningProvider = context.watch<LearningProvider>();
    final auth = context.watch<LocalAuthProvider>();
    final dashboard = dashboardProvider.dashboard;

    return Scaffold(
      appBar: AppBar(
        title: const Text('The Realm'),
        actions: [
          IconButton(
            tooltip: 'Profile & Settings',
            onPressed: _openProfile,
            icon: const Icon(Icons.person_outline),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: _buildBody(dashboardProvider, habitProvider, learningProvider, auth, dashboard),
        ),
      ),
    );
  }

  Widget _buildBody(
    DashboardProvider dashboardProvider,
    HabitProvider habitProvider,
    LearningProvider learningProvider,
    LocalAuthProvider auth,
    DashboardResponse? dashboard,
  ) {
    if (dashboardProvider.isLoading && dashboard == null) {
      return const DashboardSkeleton();
    }

    if (dashboardProvider.errorMessage != null && dashboard == null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          EmptyState(
            icon: Icons.cloud_off_outlined,
            title: 'No data available',
            message: dashboardProvider.errorMessage!,
            actionLabel: 'Retry',
            onAction: _refresh,
          ),
        ],
      );
    }

    if (dashboard == null) {
      return const SizedBox.shrink();
    }

    final viewData = DashboardViewDataMapper.from(
      response: dashboard,
      habits: habitProvider.habits,
      userDisplayName: auth.displayName,
      houseName: auth.house.name,
    );
    final house = auth.house;



    final isTablet = MediaQuery.sizeOf(context).width >= 720;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        ResponsiveFormContainer(
          child: isTablet
              ? _buildTabletLayout(viewData, learningProvider, house)
              : _buildPhoneLayout(viewData, learningProvider, house),
        ),
      ],
    );
  }

  Widget _buildPhoneLayout(
    DashboardViewData viewData,
    LearningProvider learningProvider,
    HouseTheme house,
  ) {
    return Column(
      children: [
        DashboardHeroCard(
          welcomeTitle: viewData.welcomeTitle,
          welcomeSubtitle: viewData.welcomeSubtitle,
          dayStatusMessage: viewData.dayStatusMessage,
          house: house,
          currentDate: viewData.currentDate,
          earnedPoints: viewData.summary.earnedPoints,
          possiblePoints: viewData.summary.possiblePoints,
          questCount: viewData.summary.totalHabits,
          completedQuests: viewData.summary.completedHabits,
        ),
        const SizedBox(height: AppSpacing.md),
        ProgressRingCard(summary: viewData.summary),
        const SizedBox(height: AppSpacing.md),
        UpcomingReminderCard(reminder: viewData.upcomingReminder),
        const SizedBox(height: AppSpacing.md),
        WeeklyProgressCard(days: viewData.weeklyProgress),
        const SizedBox(height: AppSpacing.md),
        StatsGrid(summary: viewData.summary),
      ],
    );
  }

  Widget _buildTabletLayout(
    DashboardViewData viewData,
    LearningProvider learningProvider,
    HouseTheme house,
  ) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: DashboardHeroCard(
                welcomeTitle: viewData.welcomeTitle,
                welcomeSubtitle: viewData.welcomeSubtitle,
                dayStatusMessage: viewData.dayStatusMessage,
                house: house,
                currentDate: viewData.currentDate,
                earnedPoints: viewData.summary.earnedPoints,
                possiblePoints: viewData.summary.possiblePoints,
                questCount: viewData.summary.totalHabits,
                completedQuests: viewData.summary.completedHabits,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: ProgressRingCard(summary: viewData.summary)),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: UpcomingReminderCard(reminder: viewData.upcomingReminder)),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: WeeklyProgressCard(days: viewData.weeklyProgress)),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        StatsGrid(summary: viewData.summary),
      ],
    );
  }
}
