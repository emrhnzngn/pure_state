import 'package:flutter/material.dart';
import 'package:pure_state/pure_state.dart';
import '../models/todo_model.dart';
import '../actions/todo_actions.dart';
import '../widgets/todo_item_widget.dart';
import '../widgets/todo_stats_widget.dart';
import '../widgets/add_todo_dialog.dart';

/// Main screen displaying the todo list
class TodoListScreen extends StatelessWidget {
  const TodoListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Todo Manager'),
        elevation: 0,
        actions: [
          // Filter button
          PureBuilder<TodoState>(
            builder: (context, state) {
              return PopupMenuButton<TodoFilter>(
                icon: const Icon(Icons.filter_list),
                tooltip: _getFilterTooltip(state.filter),
                onSelected: (filter) {
                  final store = PureProvider.of<TodoState>(context);
                  store.dispatch(SetTodoFilterAction(filter));
                },
                itemBuilder: (context) => [
                  PopupMenuItem<TodoFilter>(
                    value: TodoFilter.all,
                    child: Row(
                      children: [
                        if (state.filter == TodoFilter.all)
                          const Icon(Icons.check, size: 20)
                        else
                          const SizedBox(width: 20),
                        const Text('Tümü'),
                      ],
                    ),
                  ),
                  PopupMenuItem<TodoFilter>(
                    value: TodoFilter.active,
                    child: Row(
                      children: [
                        if (state.filter == TodoFilter.active)
                          const Icon(Icons.check, size: 20)
                        else
                          const SizedBox(width: 20),
                        const Text('Aktif'),
                      ],
                    ),
                  ),
                  PopupMenuItem<TodoFilter>(
                    value: TodoFilter.completed,
                    child: Row(
                      children: [
                        if (state.filter == TodoFilter.completed)
                          const Icon(Icons.check, size: 20)
                        else
                          const SizedBox(width: 20),
                        const Text('Tamamlanan'),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          // Settings button
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          _SearchBar(),
          // Stats widget
          const TodoStatsWidget(),
          // Category filter chips
          _CategoryFilterChips(),
          // Todo list
          Expanded(
            child: PureBuilder<TodoState>(
              builder: (context, state) {
                if (state.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: theme.colorScheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          state.error!,
                          style: TextStyle(color: theme.colorScheme.error),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            final store = PureProvider.of<TodoState>(context);
                            store.dispatch(LoadTodosAction());
                          },
                          child: const Text('Tekrar Dene'),
                        ),
                      ],
                    ),
                  );
                }

                final filteredTodos = state.filteredTodos;

                if (filteredTodos.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.assignment_outlined,
                          size: 64,
                          color: theme.colorScheme.primary.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          state.todos.isEmpty
                              ? 'Henüz todo yok\nYeni bir todo ekleyin!'
                              : 'Filtreye uygun todo bulunamadı',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: theme.textTheme.bodyMedium?.color
                                ?.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: filteredTodos.length,
                  itemBuilder: (context, index) {
                    final todo = filteredTodos[index];
                    return TodoItemWidget(todo: todo);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog<void>(
            context: context,
            builder: (context) => const AddTodoDialog(),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Yeni Todo'),
      ),
    );
  }

  String _getFilterTooltip(TodoFilter filter) {
    switch (filter) {
      case TodoFilter.all:
        return 'Filtre: Tümü';
      case TodoFilter.active:
        return 'Filtre: Aktif';
      case TodoFilter.completed:
        return 'Filtre: Tamamlanan';
    }
  }
}

/// Search bar widget
class _SearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return PureBuilder<TodoState>(
      builder: (context, state) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Todo ara...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: state.searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        final store = PureProvider.of<TodoState>(context);
                        store.dispatch(SetSearchQueryAction(''));
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
            ),
            onChanged: (query) {
              final store = PureProvider.of<TodoState>(context);
              store.dispatch(SetSearchQueryAction(query));
            },
          ),
        );
      },
    );
  }
}

/// Category filter chips widget
class _CategoryFilterChips extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return PureBuilder<TodoState>(
      builder: (context, state) {
        final categories = state.categories;
        if (categories.isEmpty) return const SizedBox.shrink();

        return Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              // All categories chip
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: FilterChip(
                  label: const Text('Tümü'),
                  selected: state.selectedCategory == null,
                  onSelected: (selected) {
                    final store = PureProvider.of<TodoState>(context);
                    store.dispatch(SetCategoryFilterAction(null));
                  },
                ),
              ),
              // Category chips
              ...categories.map((category) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    label: Text(category),
                    selected: state.selectedCategory == category,
                    onSelected: (selected) {
                      final store = PureProvider.of<TodoState>(context);
                      store.dispatch(
                        SetCategoryFilterAction(selected ? category : null),
                      );
                    },
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
