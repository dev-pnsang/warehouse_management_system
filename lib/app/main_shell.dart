import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_colors.dart';
import '../core/l10n/app_locale.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/items/presentation/items_list_screen.dart';
import '../features/categories/presentation/categories_screen.dart';
import '../features/wishlist/presentation/wishlist_screen.dart';
import '../features/items/presentation/add_item_sheet.dart';
import '../features/locations/presentation/locations_screen.dart';

final mainTabIndexProvider = StateProvider<int>((ref) => 0);

class MainShell extends ConsumerWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(mainTabIndexProvider);
    final s = ref.watch(appStringsProvider);
    final tabs = [
      const DashboardScreen(),
      const ItemsListScreen(),
      const CategoriesScreen(),
      const LocationsScreen(),
      const WishlistScreen(),
    ];
    return Scaffold(
      body: tabs[currentIndex],
      floatingActionButton: FloatingActionButton.large(
        heroTag: 'main_fab',
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const AddItemSheet(),
        ),
        child: const Icon(Icons.add, size: 32),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.dashboard_outlined), label: s.dashboard),
          BottomNavigationBarItem(icon: const Icon(Icons.list_alt), label: s.items),
          BottomNavigationBarItem(icon: const Icon(Icons.category_outlined), label: s.categories),
          BottomNavigationBarItem(icon: const Icon(Icons.place_outlined), label: s.locations),
          BottomNavigationBarItem(icon: const Icon(Icons.favorite_border), label: s.wishlist),
        ],
        onTap: (index) => ref.read(mainTabIndexProvider.notifier).state = index,
      ),
    );
  }
}

