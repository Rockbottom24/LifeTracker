import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../navigation/add_learning_page_route.dart';
import '../navigation/app_navigator.dart';
import '../providers/learning_provider.dart';
import '../widgets/learning/learning_list_card.dart';
import '../widgets/lists/async_entity_list_body.dart';
import '../widgets/offline_sync_banner.dart';

class LearningScreen extends StatefulWidget {
  const LearningScreen({super.key});

  @override
  State<LearningScreen> createState() => _LearningScreenState();
}

class _LearningScreenState extends State<LearningScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LearningProvider>().loadSessions();
    });
  }

  Future<void> _openAdd() async {
    await Navigator.of(context).push(
      AddLearningPageRoute(settings: const RouteSettings(name: '/add-learning')),
    );
    if (mounted) {
      await context.read<LearningProvider>().loadSessions();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LearningProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('The Citadel')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'learning_screen_fab',
        onPressed: _openAdd,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Study'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: SafeArea(
        child: AsyncEntityListBody(
          isLoading: provider.isLoading,
          isEmpty: provider.sessions.isEmpty,
          errorMessage: provider.errorMessage,
          onRefresh: provider.loadSessions,
          topBanner: OfflineSyncBanner(
            isOffline: provider.isOffline,
            syncMessage: provider.syncMessage,
            lastSyncedAt: provider.lastSyncedAt,
            isRefreshing: provider.isRefreshing,
            hasPendingSync: provider.hasPendingSync,
          ),
          headerTitle: 'The Citadel',
          headerSubtitle: 'Plan, track, and complete your studies.',
          loadingMessage: 'Loading archives...',
          errorTitle: 'No data available',
          emptyIcon: Icons.school_outlined,
          emptyTitle: 'No studies yet',
          emptyMessage: 'Create your first study session to get started.',
          emptyActionLabel: 'Create Session',
          onEmptyAction: _openAdd,
          itemCount: provider.sessions.length,
          itemBuilder: (context, index) {
            final session = provider.sessions[index];
            return LearningListCard(
              key: ValueKey(session.id),
              session: session,
              isPendingSync: provider.syncStatusForSession(session.id)?.isPending ?? false,
              onTap: () => AppNavigator.openLearningDetails(context, session.id),
            );
          },
        ),
      ),
    );
  }
}
