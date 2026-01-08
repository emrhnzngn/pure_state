import 'package:flutter/material.dart';
import 'package:pure_state/pure_state.dart';
import '../actions/todo_actions.dart';
import '../models/todo_model.dart';

/// Dialog for adding a new todo
class AddTodoDialog extends StatefulWidget {
  const AddTodoDialog({super.key});

  @override
  State<AddTodoDialog> createState() => _AddTodoDialogState();
}

class _AddTodoDialogState extends State<AddTodoDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedCategory = 'Genel';
  int _selectedPriority = 1;
  final List<String> _categories = ['Genel', 'İş', 'Kişisel', 'Alışveriş', 'Öğrenme'];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _addTodo() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir başlık girin')),
      );
      return;
    }

    final store = PureProvider.of<TodoState>(context);
    store.dispatch(
      AddTodoAction(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        category: _selectedCategory,
        todoPriority: _selectedPriority,
      ),
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Yeni Todo Ekle'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Başlık *',
                hintText: 'Todo başlığını girin',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Açıklama',
                hintText: 'İsteğe bağlı açıklama',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Kategori',
                border: OutlineInputBorder(),
              ),
              items: _categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedCategory = value);
                }
              },
            ),
            const SizedBox(height: 16),
            Text(
              'Öncelik',
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('Düşük')),
                ButtonSegment(value: 1, label: Text('Orta')),
                ButtonSegment(value: 2, label: Text('Yüksek')),
              ],
              selected: {_selectedPriority},
              onSelectionChanged: (Set<int> selection) {
                setState(() => _selectedPriority = selection.first);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: _addTodo,
          child: const Text('Ekle'),
        ),
      ],
    );
  }
}

