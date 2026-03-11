import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/database/app_database.dart';
import '../../../core/widgets/image_preview_screen.dart';
import '../../categories/data/categories_repository.dart';
import '../../locations/data/locations_repository.dart';
import '../data/items_repository.dart';

class ItemDetailScreen extends ConsumerStatefulWidget {
  const ItemDetailScreen({super.key, required this.itemId});

  final int itemId;

  @override
  ConsumerState<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends ConsumerState<ItemDetailScreen> {
  late Future<Item?> _itemFuture;

  @override
  void initState() {
    super.initState();
    _itemFuture = ref.read(itemsRepositoryProvider).getById(widget.itemId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Item Detail', style: TextStyle(color: AppColors.textPrimary)),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: FutureBuilder<Item?>(
        future: _itemFuture,
        builder: (context, snap) {
          if (!snap.hasData || snap.data == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final item = snap.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ImageSection(item: item),
                const SizedBox(height: 20),
                _EditableSection(item: item, ref: ref, onUpdated: () => setState(() {
                  _itemFuture = ref.read(itemsRepositoryProvider).getById(widget.itemId);
                })),
                const SizedBox(height: 24),
                const Text('Item History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                _HistorySection(itemId: item.id, ref: ref),
              ],
            ),
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete item?'),
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
    if (ok == true && mounted) {
      final item = await ref.read(itemsRepositoryProvider).getById(widget.itemId);
      if (item != null) {
        await ref.read(itemsRepositoryProvider).deleteItem(item);
        if (mounted) Navigator.of(context).pop();
      }
    }
  }
}

class _ImageSection extends StatelessWidget {
  const _ImageSection({required this.item});

  final Item item;

  @override
  Widget build(BuildContext context) {
    final file = File(item.imagePath);
    return GestureDetector(
      onTap: () {
        if (file.existsSync()) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ImagePreviewScreen(file: file),
            ),
          );
        }
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: file.existsSync()
            ? Image.file(file, height: 220, width: double.infinity, fit: BoxFit.cover)
            : Container(
                height: 220,
                color: AppColors.background,
                child: const Center(child: Icon(Icons.image_not_supported, size: 48)),
              ),
      ),
    );
  }
}

class _EditableSection extends StatelessWidget {
  const _EditableSection({required this.item, required this.ref, required this.onUpdated});

  final Item item;
  final WidgetRef ref;
  final VoidCallback onUpdated;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _EditTile(
              label: 'Name',
              value: item.name,
              onSave: (v) async {
                await ref.read(itemsRepositoryProvider).updateItem(item, name: v.isEmpty ? null : v);
                onUpdated();
              },
            ),
            _EditTile(
              label: 'Quantity',
              value: '${item.quantity}',
              onSave: (v) async {
                final q = int.tryParse(v);
                if (q != null && q >= 0) {
                  await ref.read(itemsRepositoryProvider).updateItem(item, newQuantity: q);
                  onUpdated();
                }
              },
            ),
            _EditTile(
              label: 'Notes',
              value: item.notes,
              onSave: (v) async {
                await ref.read(itemsRepositoryProvider).updateItem(item, notes: v.isEmpty ? null : v);
                onUpdated();
              },
            ),
            _EditTile(label: 'Barcode', value: item.barcode),
            _EditTile(label: 'Store', value: item.store),
            _EditTile(label: 'Serial', value: item.serialNumber),
            _EditTile(label: 'Tags', value: item.tags),
            FutureBuilder<Category?>(
              future: item.categoryId != null
                  ? ref.read(categoriesRepositoryProvider).getById(item.categoryId!)
                  : null,
              builder: (context, snap) => ListTile(
                title: const Text('Category'),
                subtitle: Text(snap.data?.name ?? 'None'),
              ),
            ),
            FutureBuilder<Location?>(
              future: item.locationId != null
                  ? ref.read(locationsRepositoryProvider).getById(item.locationId!)
                  : null,
              builder: (context, snap) => ListTile(
                title: const Text('Location'),
                subtitle: Text(snap.data?.name ?? 'None'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditTile extends StatefulWidget {
  const _EditTile({required this.label, this.value, this.onSave});

  final String label;
  final String? value;
  final Future<void> Function(String value)? onSave;

  @override
  State<_EditTile> createState() => _EditTileState();
}

class _EditTileState extends State<_EditTile> {
  bool _editing = false;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.onSave == null) {
      return ListTile(
        title: Text(widget.label),
        subtitle: Text(widget.value ?? '—'),
      );
    }
    if (!_editing) {
      return ListTile(
        title: Text(widget.label),
        subtitle: Text(widget.value ?? '—'),
        trailing: IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () => setState(() => _editing = true),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: _controller,
        decoration: InputDecoration(
          labelText: widget.label,
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.check),
                onPressed: () async {
                  await widget.onSave!(_controller.text);
                  setState(() => _editing = false);
                },
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => _editing = false),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistorySection extends StatelessWidget {
  const _HistorySection({required this.itemId, required this.ref});

  final int itemId;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ItemHistoryData>>(
      future: ref.read(itemsRepositoryProvider).getItemHistory(itemId),
      builder: (context, snap) {
        final list = snap.data ?? [];
        if (list.isEmpty) {
          return const Text('No history yet.', style: TextStyle(color: AppColors.textSecondary));
        }
        return Column(
          children: list.map((h) => ListTile(
            dense: true,
            leading: const Icon(Icons.history, size: 20, color: AppColors.textSecondary),
            title: Text(h.description),
            subtitle: Text(_formatDate(h.createdAt)),
          )).toList(),
        );
      },
    );
  }

  String _formatDate(DateTime d) {
    return '${d.day} ${_month(d.month)}: ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  String _month(int m) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return months[m - 1];
  }
}
