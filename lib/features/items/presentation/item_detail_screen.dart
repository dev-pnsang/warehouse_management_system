import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/database/app_database.dart';
import '../../../core/l10n/app_locale.dart';
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
    final s = ref.watch(appStringsProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(s.itemDetail, style: const TextStyle(color: AppColors.textPrimary)),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context, s),
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
                _EditableSection(
                  item: item,
                  ref: ref,
                  s: s,
                  onUpdated: () => setState(() {
                    _itemFuture = ref.read(itemsRepositoryProvider).getById(widget.itemId);
                  }),
                ),
                const SizedBox(height: 24),
                Text(s.itemHistory, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                _HistorySection(itemId: item.id, ref: ref, s: s),
              ],
            ),
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, AppStrings s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.deleteItemQuestion),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(s.cancel)),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.delete),
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
  const _EditableSection({required this.item, required this.ref, required this.s, required this.onUpdated});

  final Item item;
  final WidgetRef ref;
  final AppStrings s;
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
              label: s.name,
              value: item.name,
              onSave: (v) async {
                await ref.read(itemsRepositoryProvider).updateItem(item, name: v.isEmpty ? null : v);
                onUpdated();
              },
            ),
            _EditTile(
              label: s.quantity,
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
              label: s.notes,
              value: item.notes,
              onSave: (v) async {
                await ref.read(itemsRepositoryProvider).updateItem(item, notes: v.isEmpty ? null : v);
                onUpdated();
              },
            ),
            _EditTile(
              label: s.barcode,
              value: item.barcode,
              onSave: (v) async {
                await ref.read(itemsRepositoryProvider).updateItem(
                  item,
                  barcode: v.trim().isEmpty ? null : v.trim(),
                );
                onUpdated();
              },
            ),
            _EditTile(
              label: s.store,
              value: item.store,
              onSave: (v) async {
                await ref.read(itemsRepositoryProvider).updateItem(
                  item,
                  store: v.trim().isEmpty ? null : v.trim(),
                );
                onUpdated();
              },
            ),
            _EditTile(
              label: s.serial,
              value: item.serialNumber,
              onSave: (v) async {
                await ref.read(itemsRepositoryProvider).updateItem(
                  item,
                  serialNumber: v.trim().isEmpty ? null : v.trim(),
                );
                onUpdated();
              },
            ),
            _EditTile(
              label: s.tags,
              value: item.tags,
              onSave: (v) async {
                await ref.read(itemsRepositoryProvider).updateItem(
                  item,
                  tags: v.trim().isEmpty ? null : v.trim(),
                );
                onUpdated();
              },
            ),
            _EditTile(
              label: s.purchasePrice,
              value: item.purchasePrice?.toString(),
              onSave: (v) async {
                final raw = v.trim();
                if (raw.isEmpty) {
                  await ref.read(itemsRepositoryProvider).updateItem(item, purchasePrice: null);
                  onUpdated();
                  return;
                }
                final parsed = double.tryParse(raw);
                if (parsed == null) return;
                await ref.read(itemsRepositoryProvider).updateItem(item, purchasePrice: parsed);
                onUpdated();
              },
            ),
            _EditTile(
              label: s.purchaseDate,
              value: item.purchaseDate,
              onSave: (v) async {
                await ref.read(itemsRepositoryProvider).updateItem(
                  item,
                  purchaseDate: v.trim().isEmpty ? null : v.trim(),
                );
                onUpdated();
              },
            ),
            _EditTile(
              label: s.expiryDate,
              value: item.expiryDate,
              onSave: (v) async {
                await ref.read(itemsRepositoryProvider).updateItem(
                  item,
                  expiryDate: v.trim().isEmpty ? null : v.trim(),
                );
                onUpdated();
              },
            ),
            FutureBuilder<Category?>(
              future: item.categoryId != null
                  ? ref.read(categoriesRepositoryProvider).getById(item.categoryId!)
                  : null,
              builder: (context, snap) => ListTile(
                title: Text(s.category),
                subtitle: Text(snap.data?.name ?? s.none),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showCategoryPicker(context),
                ),
              ),
            ),
            FutureBuilder<Location?>(
              future: item.locationId != null
                  ? ref.read(locationsRepositoryProvider).getById(item.locationId!)
                  : null,
              builder: (context, snap) => ListTile(
                title: Text(s.location),
                subtitle: Text(snap.data?.name ?? s.none),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showLocationPicker(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCategoryPicker(BuildContext context) async {
    final categories = await ref.read(categoriesRepositoryProvider).getAll();
    int? selectedId = item.categoryId;
    if (!context.mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int?>(
                isExpanded: true,
                value: selectedId,
                decoration: InputDecoration(
                  labelText: s.category,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: [
                  DropdownMenuItem<int?>(value: null, child: Text(s.none)),
                  ...categories.map((c) => DropdownMenuItem<int?>(value: c.id, child: Text(c.name))),
                ],
                onChanged: (v) => setModalState(() => selectedId = v),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () async {
                  await ref.read(itemsRepositoryProvider).updateItem(item, categoryId: selectedId);
                  if (ctx.mounted) Navigator.of(ctx).pop();
                  onUpdated();
                },
                child: Text(s.save),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showLocationPicker(BuildContext context) async {
    final locations = await ref.read(locationsRepositoryProvider).getAll();
    int? selectedId = item.locationId;
    if (!context.mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int?>(
                isExpanded: true,
                value: selectedId,
                decoration: InputDecoration(
                  labelText: s.location,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: [
                  DropdownMenuItem<int?>(value: null, child: Text(s.none)),
                  ...locations.map((l) => DropdownMenuItem<int?>(value: l.id, child: Text(l.name))),
                ],
                onChanged: (v) => setModalState(() => selectedId = v),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () async {
                  await ref.read(itemsRepositoryProvider).updateItem(item, locationId: selectedId);
                  if (ctx.mounted) Navigator.of(ctx).pop();
                  onUpdated();
                },
                child: Text(s.save),
              ),
            ],
          ),
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
  const _HistorySection({required this.itemId, required this.ref, required this.s});

  final int itemId;
  final WidgetRef ref;
  final AppStrings s;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ItemHistoryData>>(
      future: ref.read(itemsRepositoryProvider).getItemHistory(itemId),
      builder: (context, snap) {
        final list = snap.data ?? [];
        if (list.isEmpty) {
          return Text(s.noHistoryYet, style: const TextStyle(color: AppColors.textSecondary));
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
    final months = s.isVi
        ? ['Th1', 'Th2', 'Th3', 'Th4', 'Th5', 'Th6', 'Th7', 'Th8', 'Th9', 'Th10', 'Th11', 'Th12']
        : ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[m - 1];
  }
}
