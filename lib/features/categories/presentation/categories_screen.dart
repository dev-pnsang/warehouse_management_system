import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/database/app_database.dart';
import '../data/categories_repository.dart';
import '../../locations/presentation/locations_screen.dart';

final categoriesListProvider = FutureProvider.autoDispose<List<Category>>((ref) {
  return ref.watch(categoriesRepositoryProvider).getAll();
});

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Categories', style: TextStyle(color: AppColors.textPrimary)),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.place_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const LocationsScreen()),
            ),
          ),
        ],
      ),
      body: categoriesAsync.when(
        data: (categories) {
          if (categories.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('No categories yet.', style: TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => _showAddCategory(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('Add category'),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final c = categories[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(c.name),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => _showEditCategory(context, ref, c),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _confirmDelete(context, ref, c),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: AppColors.error))),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCategory(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddCategory(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => _AddCategorySheet(
        ref: ref,
        onSubmit: (name) {
          if (name.trim().isEmpty) return;
          ref.read(categoriesRepositoryProvider).create(name.trim());
          Navigator.of(ctx).pop();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.invalidate(categoriesListProvider);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Category added'), backgroundColor: AppColors.accent),
              );
            }
          });
        },
      ),
    );
  }

  void _showEditCategory(BuildContext context, WidgetRef ref, Category c) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => _EditCategorySheet(
        ref: ref,
        category: c,
        onSubmit: () async {
          if (!context.mounted) return;
          Navigator.of(ctx).pop();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.invalidate(categoriesListProvider);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Updated'), backgroundColor: AppColors.accent),
              );
            }
          });
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Category c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete category?'),
        content: Text('Delete "${c.name}"? Items will keep their data but category will be unset.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(categoriesRepositoryProvider).delete(c);
      ref.invalidate(categoriesListProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted')));
      }
    }
  }
}

/// Bottom sheet content that owns its [TextEditingController] and disposes it when the sheet is closed.
class _AddCategorySheet extends StatefulWidget {
  const _AddCategorySheet({required this.ref, required this.onSubmit});

  final WidgetRef ref;
  final void Function(String name) onSubmit;

  @override
  State<_AddCategorySheet> createState() => _AddCategorySheetState();
}

class _AddCategorySheetState extends State<_AddCategorySheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(labelText: 'Category name'),
              autofocus: true,
              onSubmitted: (_) => widget.onSubmit(_controller.text),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => widget.onSubmit(_controller.text),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditCategorySheet extends StatefulWidget {
  const _EditCategorySheet({
    required this.ref,
    required this.category,
    required this.onSubmit,
  });

  final WidgetRef ref;
  final Category category;
  final VoidCallback onSubmit;

  @override
  State<_EditCategorySheet> createState() => _EditCategorySheetState();
}

class _EditCategorySheetState extends State<_EditCategorySheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.category.name);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(labelText: 'Category name'),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () async {
                if (_controller.text.trim().isEmpty) return;
                await widget.ref.read(categoriesRepositoryProvider).update(
                      widget.category,
                      name: _controller.text.trim(),
                    );
                if (mounted) widget.onSubmit();
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
