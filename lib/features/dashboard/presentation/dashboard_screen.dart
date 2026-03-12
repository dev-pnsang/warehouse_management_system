import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_locale.dart';
import '../../../core/preferences/user_display_name_provider.dart';
import '../../../app/main_shell.dart';
import '../providers/dashboard_providers.dart';
import '../../../core/widgets/image_preview_screen.dart';
import '../../items/presentation/item_detail_screen.dart';
import '../../settings/presentation/settings_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalItems = ref.watch(totalItemsProvider);
    final totalCategories = ref.watch(totalCategoriesProvider);
    final lowStockCount = ref.watch(lowStockCountProvider);
    final recentItems = ref.watch(recentActivityProvider);
    final s = ref.watch(appStringsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: Image.asset(
            'assets/icons/logo.png',
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Icon(Icons.inventory_2, color: AppColors.primary),
          ),
        ),
        title: Text(s.dashboard, style: const TextStyle(color: AppColors.textPrimary)),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello, ${displayNameOrDefault(ref.watch(userDisplayNameProvider))}!',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: AppColors.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your personal inventory at a glance',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    const SizedBox(height: 20),
                    _SearchChip(
                      label: s.searchItems,
                      onTap: () => ref.read(mainTabIndexProvider.notifier).state = 1,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            label: s.totalItems,
                            value: totalItems.when(
                              data: (v) => '$v',
                              loading: () => '—',
                              error: (_, __) => '—',
                            ),
                            icon: Icons.inventory_2_outlined,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            label: s.totalCategories,
                            value: totalCategories.when(
                              data: (v) => '$v',
                              loading: () => '—',
                              error: (_, __) => '—',
                            ),
                            icon: Icons.category_outlined,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _StatCard(
                      label: s.lowStock,
                      value: lowStockCount.when(
                        data: (v) => '$v',
                        loading: () => '—',
                        error: (_, __) => '—',
                      ),
                      icon: Icons.warning_amber_rounded,
                      accent: true,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          s.recentActivity,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: AppColors.textPrimary,
                              ),
                        ),
                        TextButton(
                          onPressed: () => ref.read(mainTabIndexProvider.notifier).state = 1,
                          child: Text(s.viewAll),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            recentItems.when(
              data: (items) {
                if (items.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          ref.watch(appStringsProvider).noItemsYet,
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                  );
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = items[index];
                      final file = File(item.imagePath);
                      return ListTile(
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
                          child: file.existsSync()
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    file,
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : const SizedBox(
                                  width: 48,
                                  height: 48,
                                  child: Icon(Icons.image_not_supported, color: AppColors.textSecondary),
                                ),
                        ),
                        title: Text(item.name ?? 'Unnamed'),
                        subtitle: Text('Qty: ${item.quantity}'),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ItemDetailScreen(itemId: item.id),
                          ),
                        ),
                      );
                    },
                    childCount: items.length,
                  ),
                );
              },
              loading: () => const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (e, _) => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Error: $e', style: const TextStyle(color: AppColors.error)),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }
}

class _SearchChip extends StatelessWidget {
  const _SearchChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.search, color: AppColors.textSecondary, size: 24),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    this.accent = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: accent ? AppColors.lowStock : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: accent ? AppColors.lowStock : AppColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: accent ? AppColors.lowStock : AppColors.textPrimary,
                ),
          ),
        ],
      ),
    );
  }
}
