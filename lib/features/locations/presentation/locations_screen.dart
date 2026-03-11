import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/database/app_database.dart';
import '../data/locations_repository.dart';

final locationsListProvider = FutureProvider.autoDispose<List<Location>>((ref) {
  return ref.watch(locationsRepositoryProvider).getAll();
});

class LocationsScreen extends ConsumerWidget {
  const LocationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationsAsync = ref.watch(locationsListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Locations', style: TextStyle(color: AppColors.textPrimary)),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.primary,
      ),
      body: locationsAsync.when(
        data: (locations) {
          if (locations.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('No locations yet.', style: TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => _showAddLocation(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('Add location'),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: locations.length,
            itemBuilder: (context, index) {
              final loc = locations[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.place_outlined),
                  title: Text(loc.name),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => _showEditLocation(context, ref, loc),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _confirmDelete(context, ref, loc),
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
        heroTag: 'locations_fab',
        onPressed: () => _showAddLocation(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddLocation(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Location name',
                  hintText: 'e.g. Home > Bedroom > Desk',
                ),
                autofocus: true,
                onSubmitted: (_) => _submitLocation(sheetContext, context, ref, controller.text),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => _submitLocation(sheetContext, context, ref, controller.text),
                child: const Text('Add'),
              ),
            ],
          ),
        ),
      ),
    ).then((_) => controller.dispose());
  }

  void _submitLocation(
    BuildContext sheetContext,
    BuildContext screenContext,
    WidgetRef ref,
    String name,
  ) {
    if (name.trim().isEmpty) return;
    ref.read(locationsRepositoryProvider).create(name.trim());
    Navigator.of(sheetContext).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(locationsListProvider);
      if (screenContext.mounted) {
        ScaffoldMessenger.of(screenContext).showSnackBar(
          const SnackBar(content: Text('Location added'), backgroundColor: AppColors.accent),
        );
      }
    });
  }

  void _showEditLocation(BuildContext context, WidgetRef ref, Location loc) {
    final controller = TextEditingController(text: loc.name);
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: const InputDecoration(labelText: 'Location name'),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  if (controller.text.trim().isEmpty) return;
                  await ref.read(locationsRepositoryProvider).update(loc, name: controller.text.trim());
                  Navigator.of(sheetContext).pop();
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    ref.invalidate(locationsListProvider);
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
    ).then((_) => controller.dispose());
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Location loc) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete location?'),
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
      await ref.read(locationsRepositoryProvider).delete(loc);
      ref.invalidate(locationsListProvider);
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted')));
    }
  }
}
