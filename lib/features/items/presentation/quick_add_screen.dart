import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_locale.dart';
import '../../../core/utils/image_storage.dart';
import '../../categories/data/categories_repository.dart';
import '../data/items_repository.dart';

class QuickAddScreen extends ConsumerStatefulWidget {
  const QuickAddScreen({super.key});

  @override
  ConsumerState<QuickAddScreen> createState() => _QuickAddScreenState();
}

class _QuickAddScreenState extends ConsumerState<QuickAddScreen> {
  File? _imageFile;
  String? _savedImagePath;
  int _quantity = 1;
  int? _selectedCategoryId;
  bool _saving = false;
  bool _picking = false;

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
    if (_savedImagePath == null && _imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ref.read(appStringsProvider).pleaseTakePhoto)),
      );
      return;
    }
    String imagePath = _savedImagePath ?? '';
    if (imagePath.isEmpty && _imageFile != null) {
      imagePath = await ImageStorage.saveItemImage(_imageFile!);
      setState(() => _savedImagePath = imagePath);
    }
    if (imagePath.isEmpty) return;
    setState(() => _saving = true);
    try {
      await ref.read(itemsRepositoryProvider).addItem(
            imagePath: imagePath,
            quantity: _quantity,
            categoryId: _selectedCategoryId,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ref.read(appStringsProvider).itemSaved),
            backgroundColor: AppColors.accent,
          ),
        );
        Navigator.of(context).pop();
      }
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
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(s.quickAdd, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: _picking ? null : _takePhoto,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (_imageFile != null)
                    Image.file(_imageFile!, fit: BoxFit.cover)
                  else
                    Container(
                      color: Colors.grey[900],
                      child: Center(
                        child: _picking
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.camera_alt, size: 72, color: Colors.grey[600]),
                                  const SizedBox(height: 16),
                                  Text(
                                    s.takePhoto,
                                    style: TextStyle(color: Colors.grey[400], fontSize: 18),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    s.pleaseTakePhoto,
                                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  if (_imageFile != null)
                    Positioned(
                      right: 16,
                      top: 16,
                      child: IconButton.filled(
                        onPressed: _picking ? null : _takePhoto,
                        icon: const Icon(Icons.camera_alt),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black54,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton.filled(
                        onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                        icon: const Icon(Icons.remove),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          '$_quantity',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: AppColors.textPrimary,
                              ),
                        ),
                      ),
                      IconButton.filled(
                        onPressed: () => setState(() => _quantity++),
                        icon: const Icon(Icons.add),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  Consumer(
                    builder: (context, ref, _) {
                      return FutureBuilder(
                        future: ref.read(categoriesRepositoryProvider).getAll(),
                        builder: (context, snap) {
                          final categories = snap.data ?? [];
                          if (categories.isEmpty) {
                            return Text(s.noCategories);
                          }
                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                for (final c in categories)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: FilterChip(
                                      label: Text(c.name),
                                      selected: _selectedCategoryId == c.id,
                                      onSelected: (v) =>
                                          setState(() => _selectedCategoryId = v ? c.id : null),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _saving ? null : _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        padding: const EdgeInsets.symmetric(vertical: 18),
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
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
