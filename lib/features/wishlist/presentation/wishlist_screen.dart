import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/database/app_database.dart';
import '../data/wishlist_repository.dart';

final wishlistListProvider = FutureProvider.autoDispose<List<WishlistData>>((ref) {
  return ref.watch(wishlistRepositoryProvider).getAll();
});

class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishlistAsync = ref.watch(wishlistListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Wishlist', style: TextStyle(color: AppColors.textPrimary)),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.primary,
      ),
      body: wishlistAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.favorite_border, size: 64, color: AppColors.textSecondary),
                  const SizedBox(height: 16),
                  Text('Nothing on your wishlist yet.', style: TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  Text('Add items you want to buy later.', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final w = items[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(w.name),
                  subtitle: w.notes != null && w.notes!.isNotEmpty ? Text(w.notes!) : null,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => _showEdit(context, ref, w),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _confirmDelete(context, ref, w),
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
        heroTag: 'wishlist_fab',
        onPressed: () => _showAdd(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAdd(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final notesController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Item name'),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(labelText: 'Notes (optional)'),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  if (nameController.text.trim().isEmpty) return;
                  ref.read(wishlistRepositoryProvider).add(
                        nameController.text.trim(),
                        notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                      );
                  Navigator.of(sheetContext).pop();
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    ref.invalidate(wishlistListProvider);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Added to wishlist'), backgroundColor: AppColors.accent),
                      );
                    }
                  });
                },
                child: const Text('Add to wishlist'),
              ),
            ],
          ),
        ),
      ),
    ).then((_) {
      nameController.dispose();
      notesController.dispose();
    });
  }

  void _showEdit(BuildContext context, WidgetRef ref, WishlistData w) {
    final nameController = TextEditingController(text: w.name);
    final notesController = TextEditingController(text: w.notes ?? '');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Item name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(labelText: 'Notes'),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  if (nameController.text.trim().isEmpty) return;
                  await ref.read(wishlistRepositoryProvider).update(
                        w,
                        name: nameController.text.trim(),
                        notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                      );
                  Navigator.of(sheetContext).pop();
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    ref.invalidate(wishlistListProvider);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Updated'), backgroundColor: AppColors.accent),
                      );
                    }
                  });
                },
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    ).then((_) {
      nameController.dispose();
      notesController.dispose();
    });
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, WishlistData w) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove from wishlist?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(wishlistRepositoryProvider).delete(w);
      ref.invalidate(wishlistListProvider);
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Removed')));
    }
  }
}
