import 'package:flutter/material.dart';
import 'package:pure_state/pure_state.dart';

import '../states/task_state.dart';
import '../../auth/states/user_state.dart';

/// Widget demonstrating PureComputedSelector2.
/// Computes statistics from both UserState and TaskState.
class ComputedStatisticsWidget extends StatelessWidget {
  const ComputedStatisticsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return PureComputedSelector2<UserState, TaskState, _Statistics>(
      store1: PureProvider.of<UserState>(context),
      store2: PureProvider.of<TaskState>(context),
      selector: (userState, taskState) {
        final user = userState.currentUser.dataOrNull;
        final tasks = taskState.tasks.dataOrNull;

        return _Statistics(
          userName: user?.name ?? 'Guest',
          userRole: user?.role.name ?? 'guest',
          totalTasks: tasks?.length ?? 0,
          completedTasks: tasks?.where((t) => t.completed).length ?? 0,
          activeTasks: tasks?.where((t) => !t.completed).length ?? 0,
          completionRate: tasks != null && tasks.isNotEmpty
              ? tasks.where((t) => t.completed).length / tasks.length
              : 0.0,
        );
      },
      builder: (context, stats) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // User info
              Row(
                children: [
                  CircleAvatar(
                    child: Text(
                      stats.userName[0].toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stats.userName,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          stats.userRole.toUpperCase(),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Statistics cards
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.list_alt,
                      label: 'Total',
                      value: stats.totalTasks.toString(),
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.check_circle_outline,
                      label: 'Completed',
                      value: stats.completedTasks.toString(),
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.pending_outlined,
                      label: 'Active',
                      value: stats.activeTasks.toString(),
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.trending_up,
                      label: 'Rate',
                      value: '${(stats.completionRate * 100).toInt()}%',
                      color: Colors.purple,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Statistics data class.
class _Statistics {
  const _Statistics({
    required this.userName,
    required this.userRole,
    required this.totalTasks,
    required this.completedTasks,
    required this.activeTasks,
    required this.completionRate,
  });

  final String userName;
  final String userRole;
  final int totalTasks;
  final int completedTasks;
  final int activeTasks;
  final double completionRate;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _Statistics &&
          runtimeType == other.runtimeType &&
          userName == other.userName &&
          userRole == other.userRole &&
          totalTasks == other.totalTasks &&
          completedTasks == other.completedTasks &&
          activeTasks == other.activeTasks &&
          completionRate == other.completionRate;

  @override
  int get hashCode => Object.hash(
        userName,
        userRole,
        totalTasks,
        completedTasks,
        activeTasks,
        completionRate,
      );
}

/// Statistic card widget.
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

