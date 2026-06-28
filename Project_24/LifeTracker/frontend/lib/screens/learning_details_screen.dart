import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/learning_session_response.dart';
import '../models/learning_status.dart';
import '../navigation/add_learning_page_route.dart';
import '../providers/learning_provider.dart';
import '../theme/app_spacing.dart';
import '../utils/learning_notification_helper.dart';
import '../utils/learning_ui_utils.dart';
import '../widgets/app_card.dart';
import '../widgets/confirmation_dialog.dart';
import '../widgets/detail_header_card.dart';
import '../widgets/detail_info_row.dart';
import '../widgets/primary_button.dart';
import '../widgets/responsive_form_container.dart';

class LearningDetailsScreen extends StatefulWidget {
  const LearningDetailsScreen({super.key, required this.sessionId});

  final int sessionId;

  @override
  State<LearningDetailsScreen> createState() => _LearningDetailsScreenState();
}

class _LearningDetailsScreenState extends State<LearningDetailsScreen> {
  Timer? _timer;
  int _elapsedSeconds = 0;
  bool _timerRunning = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<LearningProvider>();
      if (provider.findSessionById(widget.sessionId) == null) {
        await provider.loadSessions();
      }
      if (!mounted) return;
      final session = provider.findSessionById(widget.sessionId);
      if (session?.statusEnum == LearningStatus.inProgress) {
        _startTimer();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _timerRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsedSeconds++);
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() => _timerRunning = false);
  }

  String get _elapsedLabel {
    final minutes = _elapsedSeconds ~/ 60;
    final seconds = _elapsedSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _startLearning(LearningSessionResponse session) async {
    final provider = context.read<LearningProvider>();
    final updated = await provider.startSession(session.id);
    if (!mounted || updated == null) return;
    setState(() => _elapsedSeconds = 0);
    _startTimer();
  }

  Future<void> _completeLearning(LearningSessionResponse session) async {
    _stopTimer();
    final totalMinutes = session.completedMinutes + (_elapsedSeconds / 60).ceil();
    final provider = context.read<LearningProvider>();
    await provider.completeSession(session.id, totalMinutes.clamp(1, 9999));
    if (mounted) setState(() {});
  }

  Future<void> _openEdit(LearningSessionResponse session) async {
    await Navigator.of(context).push(
      AddLearningPageRoute(
        settings: RouteSettings(name: '/edit-learning/${session.id}'),
        session: session,
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _delete(LearningSessionResponse session) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Delete session',
      message: 'Delete "${session.title}"?',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (confirmed != true || !mounted) return;
    await LearningNotificationHelper.cancelForSession(session.id);
    if (!mounted) return;
    final provider = context.read<LearningProvider>();
    final ok = await provider.deleteSession(session.id);
    if (mounted && ok) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LearningProvider>();
    final session = provider.findSessionById(widget.sessionId);
    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Learning Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final theme = Theme.of(context);
    final accent = LearningUiUtils.colorFromHex(session.colorHex, theme.colorScheme);
    final dateFormat = DateFormat.yMMMd();
    final inProgress = _timerRunning || session.statusEnum == LearningStatus.inProgress;

    return Scaffold(
      appBar: AppBar(title: const Text('Learning Details')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenHorizontal,
            AppSpacing.lg,
            AppSpacing.screenHorizontal,
            AppSpacing.xl,
          ),
          children: [
            ResponsiveFormContainer(
              child: Column(
                children: [
                  DetailHeaderCard(
                    icon: LearningUiUtils.iconFromName(session.iconName),
                    iconColor: accent,
                    title: session.title,
                    subtitle: session.description,
                    chips: [
                      DetailStatChip(
                        label: session.priorityEnum.label,
                        color: theme.colorScheme.secondaryContainer,
                      ),
                      DetailStatChip(
                        label: session.statusEnum.label,
                        color: theme.colorScheme.primaryContainer,
                      ),
                    ],
                  ),
                  if (inProgress) ...[
                    const SizedBox(height: AppSpacing.sectionGap),
                    AppCard(
                      elevation: 1,
                      margin: EdgeInsets.zero,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.xl,
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Elapsed time',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            _elapsedLabel,
                            style: theme.textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: accent,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sectionGap),
                  AppCard(
                    elevation: 1,
                    margin: EdgeInsets.zero,
                    padding: const EdgeInsets.all(AppSpacing.cardPadding),
                    child: Column(
                      children: [
                        DetailInfoRow(icon: Icons.topic_outlined, label: 'Topic', value: session.topic ?? 'General'),
                        DetailInfoRow(icon: Icons.timelapse, label: 'Progress', value: '${session.progressPercent}%'),
                        DetailInfoRow(icon: Icons.hourglass_bottom, label: 'Time spent', value: '${session.completedMinutes} min'),
                        DetailInfoRow(
                          icon: Icons.event,
                          label: 'Scheduled',
                          value: session.scheduledDate == null ? 'Not set' : dateFormat.format(session.scheduledDate!),
                        ),
                        DetailInfoRow(icon: Icons.schedule, label: 'Reminder', value: session.formattedReminderTime ?? 'Not set'),
                        DetailInfoRow(
                          icon: Icons.notifications,
                          label: 'Notifications',
                          value: session.notificationsEnabled ? 'Enabled' : 'Disabled',
                          showDivider: false,
                        ),
                      ],
                    ),
                  ),
                  DetailActionsSection(
                    children: [
                      if (session.statusEnum != LearningStatus.completed)
                        PrimaryButton(
                          label: session.statusEnum == LearningStatus.inProgress ? 'Complete Learning' : 'Start Learning',
                          expand: true,
                          icon: session.statusEnum == LearningStatus.inProgress ? Icons.check_rounded : Icons.play_arrow_rounded,
                          onPressed: () {
                            if (session.statusEnum == LearningStatus.inProgress) {
                              _completeLearning(session);
                            } else {
                              _startLearning(session);
                            }
                          },
                        ),
                      if (session.statusEnum != LearningStatus.completed) const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: SecondaryActionButton(
                              label: 'Edit',
                              icon: Icons.edit_outlined,
                              onPressed: () => _openEdit(session),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: SecondaryActionButton(
                              label: 'Delete',
                              icon: Icons.delete_outline,
                              isDestructive: true,
                              onPressed: () => _delete(session),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
