import 'package:flutter/material.dart';
import 'package:pure_state/pure_state.dart';
import '../models/todo_model.dart';

/// Widget that displays todo statistics using PureSelector
class TodoStatsWidget extends StatelessWidget {
  const TodoStatsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PureSelector<TodoState, TodoStats>(
      store: PureProvider.of<TodoState>(context),
      selector: (state) => state.stats,
      builder: (context, stats) {
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.primary.withOpacity(0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(
                icon: Icons.assignment,
                label: 'Toplam',
                value: stats.total.toString(),
                color: Colors.white,
              ),
              _StatItem(
                icon: Icons.check_circle,
                label: 'Tamamlanan',
                value: stats.completed.toString(),
                color: Colors.green.shade200,
              ),
              _StatItem(
                icon: Icons.pending,
                label: 'Aktif',
                value: stats.active.toString(),
                color: Colors.orange.shade200,
              ),
              _StatItem(
                icon: Icons.priority_high,
                label: 'Yüksek Öncelik',
                value: stats.highPriority.toString(),
                color: Colors.red.shade200,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
      ],
    );
  }
}

