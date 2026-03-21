import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/database/app_database.dart';
import '../data/locations_repository.dart';

final locationsListProvider = StreamProvider.autoDispose<List<Location>>((ref) {
  return ref.watch(locationsRepositoryProvider).watchAll();
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
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddLocation(context, ref),
          ),
        ],
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
    );
  }

  void _showAddLocation(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => _AddLocationSheet(
        onSubmit: (name) => _submitLocation(sheetContext, context, ref, name),
      ),
    );
  }

  Future<void> _submitLocation(
    BuildContext sheetContext,
    BuildContext screenContext,
    WidgetRef ref,
    String name,
  ) async {
    if (name.trim().isEmpty) return;
    try {
      await ref.read(locationsRepositoryProvider).create(name.trim());
      if (sheetContext.mounted) {
        Navigator.of(sheetContext).pop();
      }
      if (screenContext.mounted) {
        ScaffoldMessenger.of(screenContext).showSnackBar(
          const SnackBar(content: Text('Location added'), backgroundColor: AppColors.accent),
        );
      }
    } catch (e) {
      if (screenContext.mounted) {
        ScaffoldMessenger.of(screenContext).showSnackBar(
          SnackBar(content: Text('Create failed: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _showEditLocation(BuildContext context, WidgetRef ref, Location loc) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => _EditLocationSheet(
        location: loc,
        onSubmit: (name) async {
          if (name.trim().isEmpty) return;
          try {
            await ref.read(locationsRepositoryProvider).update(loc, name: name.trim());
            if (sheetContext.mounted) {
              Navigator.of(sheetContext).pop();
            }
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Updated'), backgroundColor: AppColors.accent),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Update failed: $e'), backgroundColor: AppColors.error),
              );
            }
          }
        },
      ),
    );
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
      try {
        await ref.read(locationsRepositoryProvider).delete(loc);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted')));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Delete failed: $e'), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }
}

class _AddLocationSheet extends StatefulWidget {
  const _AddLocationSheet({required this.onSubmit});

  final Future<void> Function(String name) onSubmit;

  @override
  State<_AddLocationSheet> createState() => _AddLocationSheetState();
}

class _AddLocationSheetState extends State<_AddLocationSheet> {
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
              decoration: const InputDecoration(
                labelText: 'Location name',
                hintText: 'e.g. Home > Bedroom > Desk',
              ),
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

class _EditLocationSheet extends StatefulWidget {
  const _EditLocationSheet({required this.location, required this.onSubmit});

  final Location location;
  final Future<void> Function(String name) onSubmit;

  @override
  State<_EditLocationSheet> createState() => _EditLocationSheetState();
}

class _EditLocationSheetState extends State<_EditLocationSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.location.name);
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
              decoration: const InputDecoration(labelText: 'Location name'),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => widget.onSubmit(_controller.text),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
