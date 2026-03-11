import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_locale.dart';
import '../../../core/utils/image_storage.dart';
import '../../categories/data/categories_repository.dart';
import '../../locations/data/locations_repository.dart';
import '../data/items_repository.dart';

/// Bottom sheet to add item: take photo on current screen, then enter name, quantity, category, location.
class AddItemSheet extends ConsumerStatefulWidget {
  const AddItemSheet({super.key});

  @override
  ConsumerState<AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends ConsumerState<AddItemSheet> {
  File? _imageFile;
  final TextEditingController _nameController = TextEditingController();
  int _quantity = 1;
  int? _selectedCategoryId;
  int? _selectedLocationId;
  bool _picking = false;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    if (_picking) return;
    setState(() => _picking = true);
    try {
      final picker = ImagePicker();
      final xFile = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (xFile != null && mounted) {
        setState(() {
          _imageFile = File(xFile.path);
          _picking = false;
        });
      } else if (mounted) {
        setState(() => _picking = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _picking = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _save() async {
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ref.read(appStringsProvider).pleaseTakePhoto)),
      );
      return;
    }
    final name = _nameController.text.trim();
    final quantity = _quantity;
    final categoryId = _selectedCategoryId;
    final locationId = _selectedLocationId;
    final imageFile = _imageFile!;
    setState(() => _saving = true);
    try {
      final imagePath = await ImageStorage.saveItemImage(imageFile);
      if (!mounted) return;
      await ref.read(itemsRepositoryProvider).addItem(
            imagePath: imagePath,
            name: name.isEmpty ? null : name,
            quantity: quantity,
            categoryId: categoryId,
            locationId: locationId,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ref.read(appStringsProvider).itemSaved),
          backgroundColor: AppColors.accent,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(appStringsProvider);
    final maxHeight = MediaQuery.of(context).size.height * 0.9;
    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  s.addItem,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                // Photo area: tap to take photo (no navigation)
                GestureDetector(
                  onTap: _picking ? null : _takePhoto,
                  child: Container(
                    height: 160,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _imageFile != null
                          ? Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.file(_imageFile!, fit: BoxFit.cover),
                                Positioned(
                                  right: 8,
                                  top: 8,
                                  child: IconButton.filled(
                                    onPressed: _picking ? null : _takePhoto,
                                    icon: const Icon(Icons.camera_alt, color: Colors.white),
                                    style: IconButton.styleFrom(
                                      backgroundColor: Colors.black54,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Center(
                              child: _picking
                                  ? const CircularProgressIndicator()
                                  : Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.camera_alt, size: 48, color: Colors.grey[600]),
                                        const SizedBox(height: 8),
                                        Text(
                                          s.takePhoto,
                                          style: TextStyle(color: Colors.grey[700], fontSize: 16),
                                        ),
                                      ],
                                    ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Name
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: s.itemName,
                    hintText: s.itemNameHint,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: AppColors.surface,
                  ),
                ),
                const SizedBox(height: 16),
                // Quantity
                Row(
                  children: [
                    Text(s.quantity, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
                    const SizedBox(width: 16),
                    IconButton.filled(
                      onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                      icon: const Icon(Icons.remove),
                      style: IconButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text('$_quantity', style: Theme.of(context).textTheme.titleLarge),
                    ),
                    IconButton.filled(
                      onPressed: () => setState(() => _quantity++),
                      icon: const Icon(Icons.add),
                      style: IconButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Categories
                FutureBuilder(
                  future: ref.read(categoriesRepositoryProvider).getAll(),
                  builder: (context, snap) {
                    final categories = snap.data ?? [];
                    if (categories.isEmpty) {
                      return Text(s.noCategories, style: TextStyle(color: AppColors.textSecondary, fontSize: 13));
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(s.categories, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: categories.map(
                            (c) => FilterChip(
                              label: Text(c.name),
                              selected: _selectedCategoryId == c.id,
                              onSelected: (v) => setState(() => _selectedCategoryId = v ? c.id : null),
                            ),
                          ).toList(),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),
                // Location
                FutureBuilder(
                  future: ref.read(locationsRepositoryProvider).getAll(),
                  builder: (context, snap) {
                    final locations = snap.data ?? [];
                    return DropdownButtonFormField<int?>(
                      value: _selectedLocationId,
                      decoration: InputDecoration(
                        labelText: s.selectLocation,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: AppColors.surface,
                      ),
                      items: [
                        DropdownMenuItem<int?>(value: null, child: Text(s.noLocation)),
                        ...locations.map(
                          (loc) => DropdownMenuItem<int?>(value: loc.id, child: Text(loc.name)),
                        ),
                      ],
                      onChanged: (v) => setState(() => _selectedLocationId = v),
                    );
                  },
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: (_saving || _imageFile == null) ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _saving
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(s.saveInstantly, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
