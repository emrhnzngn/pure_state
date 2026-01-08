import 'package:flutter/material.dart';
import 'package:pure_state/pure_state.dart';
import '../models/todo_model.dart';
import '../actions/todo_actions.dart';

/// Widget that displays a single todo item
class TodoItemWidget extends StatelessWidget {
  final Todo todo;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const TodoItemWidget({
    super.key,
    required this.todo,
    this.onTap,
    this.onDelete,
  });

  Color _getPriorityColor(int priority) {
    switch (priority) {
      case 2:
        return Colors.red;
      case 1:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getPriorityText(int priority) {
    switch (priority) {
      case 2:
        return 'Yüksek';
      case 1:
        return 'Orta';
      default:
        return 'Düşük';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _getPriorityColor(todo.priority).withOpacity(0.3),
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Checkbox
              Checkbox(
                value: todo.isCompleted,
                onChanged: (value) {
                  final store = PureProvider.of<TodoState>(context);
                  store.dispatch(ToggleTodoAction(todo.id));
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      todo.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        decoration: todo.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                        color: todo.isCompleted
                            ? theme.textTheme.bodyMedium?.color?.withOpacity(0.5)
                            : null,
                      ),
                    ),
                    if (todo.description != null && todo.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        todo.description!,
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                          decoration: todo.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // Category badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            todo.category,
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Priority badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getPriorityColor(todo.priority).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _getPriorityText(todo.priority),
                            style: TextStyle(
                              fontSize: 12,
                              color: _getPriorityColor(todo.priority),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const Spacer(),
                        // Date
                        Text(
                          _formatDate(todo.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Delete button
              IconButton(
                icon: const Icon(Icons.delete_outline),
                color: Colors.red,
                onPressed: onDelete ?? () {
                  final store = PureProvider.of<TodoState>(context);
                  store.dispatch(DeleteTodoAction(todo.id));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Bugün';
    } else if (difference.inDays == 1) {
      return 'Dün';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} gün önce';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

