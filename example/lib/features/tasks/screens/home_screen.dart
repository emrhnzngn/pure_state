import 'package:flutter/material.dart';
import 'package:pure_state/pure_state.dart';

import '../actions/task_actions.dart';
import '../../auth/actions/user_actions.dart';
import '../states/task_state.dart';
import '../../auth/states/user_state.dart';
import '../../settings/screens/settings_screen.dart';
import '../widgets/computed_statistics_widget.dart';
import '../widgets/task_list_widget.dart';

/// Home screen showing tasks with computed statistics.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Load tasks on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userStore = PureProvider.of<UserState>(context);
      final taskStore = PureProvider.of<TaskState>(context);

      final userId = userStore.state.currentUser.dataOrNull?.id;
      if (userId != null) {
        taskStore.dispatch(LoadTasksAction(userId));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: PureBuilder<UserState>(
          builder: (context, state) {
            final user = state.currentUser.dataOrNull;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Task Manager'),
                if (user != null)
                  Text(
                    'Hello, ${user.name}',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.white70),
                  ),
              ],
            );
          },
        ),
        actions: [
          // Settings button
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),

          // Logout button
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              final store = PureProvider.of<UserState>(context);
              store.dispatch(LogoutAction());
            },
          ),
        ],
      ),
      body: const Column(
        children: [
          // Computed Statistics (using PureComputedSelector)
          ComputedStatisticsWidget(),

          // Task Filter
          _TaskFilterBar(),

          // Task List
          Expanded(child: TaskListWidget()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTaskDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('New Task'),
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Create New Task'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final taskStore = PureProvider.of<TaskState>(context);
              taskStore.dispatch(
                CreateTaskAction(
                  title: titleController.text,
                  description: descController.text,
                ),
              );
              Navigator.pop(dialogContext);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

/// Task filter bar widget.
class _TaskFilterBar extends StatelessWidget {
  const _TaskFilterBar();

  @override
  Widget build(BuildContext context) {
    return PureSelector<TaskState, TaskFilter>(
      store: PureProvider.of<TaskState>(context),
      selector: (state) => state.filter,
      builder: (context, filter) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: TaskFilter.values.map((f) {
              final isSelected = f == filter;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(f.displayName),
                  selected: isSelected,
                  onSelected: (_) {
                    final store = PureProvider.of<TaskState>(context);
                    store.dispatch(SetFilterAction(f));
                  },
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
