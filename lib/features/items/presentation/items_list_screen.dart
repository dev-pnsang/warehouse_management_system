import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/database/app_database.dart';
import '../../categories/data/categories_repository.dart';
import '../data/items_repository.dart';
import 'item_detail_screen.dart';
import 'quick_add_screen.dart';
import 'barcode_scanner_screen.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');
final selectedCategoryFilterProvider = StateProvider<int?>((ref) => null);

class ItemsListScreen extends ConsumerStatefulWidget {
  const ItemsListScreen({super.key});

  @override
  ConsumerState<ItemsListScreen> createState() => _ItemsListScreenState();
}

class _ItemsListScreenState extends ConsumerState<ItemsListScreen> {
  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);
    final categoryId = ref.watch(selectedCategoryFilterProvider);
    final itemsStream = ref.watch(itemsRepositoryProvider).watchSearch(query);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Items', style: TextStyle(color: AppColors.textPrimary)),
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
          FutureBuilder<List<Category>>(
            future: ref.read(categoriesRepositoryProvider).getAll(),
            builder: (context, snap) {
              final categories = snap.data ?? [];
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    ChoiceChip(
                      label: const Text('All'),
                      selected: categoryId == null,
                      onSelected: (_) => ref.read(selectedCategoryFilterProvider.notifier).state = null,
                    ),
                    const SizedBox(width: 8),
                    ...categories.map(
                      (c) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(c.name),
                          selected: categoryId == c.id,
                          onSelected: (_) =>
                              ref.read(selectedCategoryFilterProvider.notifier).state = c.id,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<List<Item>>(
              stream: itemsStream,
              builder: (context, snap) {
                var items = snap.data ?? [];
                if (categoryId != null) {
                  items = items.where((i) => i.categoryId == categoryId).toList();
                }
                return _ItemList(items: items, ref: ref);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const QuickAddScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _ItemList extends StatelessWidget {
  const _ItemList({required this.items, required this.ref});

  final List<Item> items;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Text(
          'No items. Tap + to add.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _ItemCard(item: item, ref: ref);
      },
    );
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({required this.item, required this.ref});

  final Item item;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final file = File(item.imagePath);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: ClipRRect(
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
        title: Text(
          item.name ?? 'Unnamed',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: FutureBuilder<Category?>(
          future: item.categoryId != null
              ? ref.read(categoriesRepositoryProvider).getById(item.categoryId!)
              : null,
          builder: (context, snap) {
            return Text(snap.data?.name ?? 'No category');
          },
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
