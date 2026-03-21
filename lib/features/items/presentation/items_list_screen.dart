import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_locale.dart';
import '../../../core/database/app_database.dart';
import '../../categories/data/categories_repository.dart';
import '../../locations/data/locations_repository.dart';
import '../data/items_repository.dart';
import '../../../core/widgets/image_preview_screen.dart';
import 'item_detail_screen.dart';
import 'add_item_sheet.dart';
import 'barcode_scanner_screen.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');
final selectedCategoryFilterProvider = StateProvider<int?>((ref) => null);
final selectedLocationFilterProvider = StateProvider<int?>((ref) => null);

class ItemsListScreen extends ConsumerStatefulWidget {
  const ItemsListScreen({super.key});

  @override
  ConsumerState<ItemsListScreen> createState() => _ItemsListScreenState();
}

class _ItemsListScreenState extends ConsumerState<ItemsListScreen> {
  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final query = ref.watch(searchQueryProvider);
    final categoryId = ref.watch(selectedCategoryFilterProvider);
    final locationId = ref.watch(selectedLocationFilterProvider);
    final itemsStream = ref.watch(itemsRepositoryProvider).watchAll();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(s.items, style: const TextStyle(color: AppColors.textPrimary)),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.document_scanner),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by name, barcode, tags...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: AppColors.surface,
              ),
              onChanged: (v) => ref.read(searchQueryProvider.notifier).state = v,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: FutureBuilder<List<Category>>(
                    future: ref.read(categoriesRepositoryProvider).getAll(),
                    builder: (context, snap) {
                      final categories = snap.data ?? [];
                      final hasSelectedCategory = categories.any((c) => c.id == categoryId);
                      final safeCategoryValue = hasSelectedCategory ? categoryId : null;
                      return DropdownButtonFormField<int?>(
                        isExpanded: true,
                        value: safeCategoryValue,
                        decoration: InputDecoration(
                          labelText: s.filterCategory,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: AppColors.surface,
                        ),
                        items: [
                          DropdownMenuItem<int?>(value: null, child: Text(s.all)),
                          ...categories.map(
                            (c) => DropdownMenuItem<int?>(value: c.id, child: Text(c.name)),
                          ),
                        ],
                        onChanged: (v) => ref.read(selectedCategoryFilterProvider.notifier).state = v,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FutureBuilder<List<Location>>(
                    future: ref.read(locationsRepositoryProvider).getAll(),
                    builder: (context, snap) {
                      final locations = snap.data ?? [];
                      final hasSelectedLocation = locations.any((loc) => loc.id == locationId);
                      final safeLocationValue = hasSelectedLocation ? locationId : null;
                      return DropdownButtonFormField<int?>(
                        isExpanded: true,
                        value: safeLocationValue,
                        decoration: InputDecoration(
                          labelText: s.filterLocation,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: AppColors.surface,
                        ),
                        items: [
                          DropdownMenuItem<int?>(value: null, child: Text(s.all)),
                          ...locations.map(
                            (loc) => DropdownMenuItem<int?>(value: loc.id, child: Text(loc.name)),
                          ),
                        ],
                        onChanged: (v) => ref.read(selectedLocationFilterProvider.notifier).state = v,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<List<Item>>(
              stream: itemsStream,
              builder: (context, snap) {
                var items = snap.data ?? [];
                final q = query.trim().toLowerCase();
                if (q.isNotEmpty) {
                  items = items.where((i) {
                    final name = (i.name ?? '').toLowerCase();
                    final barcode = (i.barcode ?? '').toLowerCase();
                    final tags = (i.tags ?? '').toLowerCase();
                    return name.contains(q) || barcode.contains(q) || tags.contains(q);
                  }).toList();
                }
                if (categoryId != null) {
                  items = items.where((i) => i.categoryId == categoryId).toList();
                }
                if (locationId != null) {
                  items = items.where((i) => i.locationId == locationId).toList();
                }
                return _ItemList(items: items, ref: ref, s: s);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'items_fab',
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const AddItemSheet(),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _ItemList extends StatelessWidget {
  const _ItemList({required this.items, required this.ref, required this.s});

  final List<Item> items;
  final WidgetRef ref;
  final AppStrings s;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Text(
          s.noItemsYet,
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _ItemCard(item: item, ref: ref, s: s);
      },
    );
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({required this.item, required this.ref, required this.s});

  final Item item;
  final WidgetRef ref;
  final AppStrings s;

  @override
  Widget build(BuildContext context) {
    final file = File(item.imagePath);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: GestureDetector(
          behavior: HitTestBehavior.opaque,
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
            borderRadius: BorderRadius.circular(8),
            child: file.existsSync()
                ? Image.file(file, width: 56, height: 56, fit: BoxFit.cover)
                : Container(
                    width: 56,
                    height: 56,
                    color: AppColors.background,
                    child: const Icon(Icons.image_not_supported),
                  ),
          ),
        ),
        isThreeLine: true,
        title: Text(
          item.name ?? s.unnamed,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              FutureBuilder<Category?>(
                future: item.categoryId != null
                    ? ref.read(categoriesRepositoryProvider).getById(item.categoryId!)
                    : null,
                builder: (context, snap) {
                  final name = snap.data?.name ?? s.noCategory;
                  return _ItemMetaLine(
                    icon: Icons.category_outlined,
                    label: s.category,
                    value: name,
                    iconColor: AppColors.primary,
                    labelColor: AppColors.primary.withOpacity(0.85),
                  );
                },
              ),
              const SizedBox(height: 6),
              FutureBuilder<Location?>(
                future: item.locationId != null
                    ? ref.read(locationsRepositoryProvider).getById(item.locationId!)
                    : null,
                builder: (context, snap) {
                  final name = snap.data?.name ?? s.noLocation;
                  return _ItemMetaLine(
                    icon: Icons.place_outlined,
                    label: s.location,
                    value: name,
                    iconColor: AppColors.accent,
                    labelColor: AppColors.accent.withOpacity(0.9),
                  );
                },
              ),
            ],
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '×${item.quantity}',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              fontSize: 16,
            ),
          ),
        ),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ItemDetailScreen(itemId: item.id)),
        ),
        onLongPress: () => _showSwipeAdd(context),
      ),
    );
  }

  void _showSwipeAdd(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Quick add +1 to quantity?', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                  FilledButton(
                    onPressed: () {
                      ref.read(itemsRepositoryProvider).addQuantity(item, 1);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('+1 added'), backgroundColor: AppColors.accent),
                      );
                    },
                    child: const Text('Add +1'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Một dòng meta (danh mục / vị trí): icon + nhãn cố định + giá trị — dễ phân biệt.
class _ItemMetaLine extends StatelessWidget {
  const _ItemMetaLine({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
    required this.labelColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;
  final Color labelColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 6),
        Expanded(
          child: RichText(
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.25,
                  ),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: labelColor,
                    fontSize: 12,
                  ),
                ),
                TextSpan(
                  text: value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
