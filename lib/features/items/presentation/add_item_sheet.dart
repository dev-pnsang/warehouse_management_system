import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_locale.dart';
import '../../../core/utils/image_storage.dart';
import '../../categories/data/categories_repository.dart';
import '../../locations/data/locations_repository.dart';
import '../data/items_repository.dart';

/// Bottom sheet to add item: take photo (image_picker), then enter name, quantity, category, location.
/// Ghi chú: Hiện dùng image_picker (mở camera hệ thống) vì package camera 0.11 lỗi build với Flutter mới (camera_android_camerax SurfaceProducer). Khi nâng Flutter 3.41+ (Dart 3.9+) có thể dùng camera: ^0.12.0 để có preview ngay trong sheet.
class AddItemSheet extends ConsumerStatefulWidget {
  const AddItemSheet({super.key});

  @override
  ConsumerState<AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends ConsumerState<AddItemSheet> {
  File? _imageFile;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _barcodeController = TextEditingController();
  final TextEditingController _purchasePriceController = TextEditingController();
  final TextEditingController _purchaseDateController = TextEditingController();
  final TextEditingController _expiryDateController = TextEditingController();
  final TextEditingController _storeController = TextEditingController();
  final TextEditingController _serialController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  int _quantity = 1;
  int? _selectedCategoryId;
  int? _selectedLocationId;
  bool _saving = false;
  bool _picking = false;
  int _rotationQuarterTurns = 0;

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    _barcodeController.dispose();
    _purchasePriceController.dispose();
    _purchaseDateController.dispose();
    _expiryDateController.dispose();
    _storeController.dispose();
    _serialController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    if (_picking || !mounted) return;
    setState(() => _picking = true);
    debugPrint('[AddItemSheet] Mở camera (image_picker)...');
    try {
      final picker = ImagePicker();
      final xFile = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (xFile != null && mounted) {
        debugPrint('[AddItemSheet] Đã chụp: ${xFile.path}');
        setState(() {
          _imageFile = File(xFile.path);
          _picking = false;
          _rotationQuarterTurns = 0;
        });
      } else if (mounted) {
        setState(() => _picking = false);
      }
    } catch (e, st) {
      debugPrint('[AddItemSheet] Lỗi camera: $e\n$st');
      if (mounted) {
        setState(() => _picking = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi camera: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _retakePhoto() {
    setState(() {
      _imageFile = null;
      _rotationQuarterTurns = 0;
    });
  }

  void _rotatePhotoPreview() {
    if (_imageFile == null) return;
    setState(() => _rotationQuarterTurns = (_rotationQuarterTurns + 1) % 4);
  }

  Future<File> _applyRotationIfNeeded(File source) async {
    if (_rotationQuarterTurns == 0) return source;
    final bytes = await source.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return source;
    final rotated = img.copyRotate(decoded, angle: (_rotationQuarterTurns * 90).toDouble());
    final encoded = img.encodeJpg(rotated, quality: 92);
    final outFile = File('${source.path}_rot${_rotationQuarterTurns}.jpg');
    await outFile.writeAsBytes(encoded, flush: true);
    return outFile;
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
    final notes = _notesController.text.trim();
    final barcode = _barcodeController.text.trim();
    final purchasePriceText = _purchasePriceController.text.trim();
    final purchaseDate = _purchaseDateController.text.trim();
    final expiryDate = _expiryDateController.text.trim();
    final store = _storeController.text.trim();
    final serialNumber = _serialController.text.trim();
    final tags = _tagsController.text.trim();
    final purchasePrice = purchasePriceText.isEmpty ? null : double.tryParse(purchasePriceText);
    final imageFile = _imageFile!;
    setState(() => _saving = true);
    try {
      final fileToSave = await _applyRotationIfNeeded(imageFile);
      final imagePath = await ImageStorage.saveItemImage(fileToSave);
      if (!mounted) return;
      await ref.read(itemsRepositoryProvider).addItem(
            imagePath: imagePath,
            name: name.isEmpty ? null : name,
            quantity: quantity,
            categoryId: categoryId,
            locationId: locationId,
            notes: notes.isEmpty ? null : notes,
            barcode: barcode.isEmpty ? null : barcode,
            purchasePrice: purchasePrice,
            purchaseDate: purchaseDate.isEmpty ? null : purchaseDate,
            expiryDate: expiryDate.isEmpty ? null : expiryDate,
            store: store.isEmpty ? null : store,
            serialNumber: serialNumber.isEmpty ? null : serialNumber,
            tags: tags.isEmpty ? null : tags,
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
                GestureDetector(
                  onTap: _picking ? null : _takePhoto,
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _imageFile != null
                          ? Stack(
                              fit: StackFit.expand,
                              children: [
                                RotatedBox(
                                  quarterTurns: _rotationQuarterTurns,
                                  child: Image.file(_imageFile!, fit: BoxFit.cover),
                                ),
                                Positioned(
                                  right: 8,
                                  top: 8,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton.filled(
                                        onPressed: _rotatePhotoPreview,
                                        icon: const Icon(Icons.rotate_right, color: Colors.white),
                                        style: IconButton.styleFrom(backgroundColor: Colors.black54),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton.filled(
                                        onPressed: _retakePhoto,
                                        icon: const Icon(Icons.camera_alt, color: Colors.white),
                                        style: IconButton.styleFrom(backgroundColor: Colors.black54),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          : Center(
                              child: _picking
                                  ? const Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        CircularProgressIndicator(color: Colors.white),
                                        SizedBox(height: 12),
                                        Text('Đang mở camera...', style: TextStyle(color: Colors.white70)),
                                      ],
                                    )
                                  : Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.camera_alt, size: 56, color: Colors.grey[400]),
                                        const SizedBox(height: 12),
                                        Text(s.takePhoto, style: TextStyle(color: Colors.grey[400], fontSize: 16)),
                                        const SizedBox(height: 4),
                                        Text('Chạm để chụp ảnh', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                                      ],
                                    ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
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
                TextField(
                  controller: _notesController,
                  decoration: InputDecoration(
                    labelText: s.notes,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: AppColors.surface,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _barcodeController,
                  decoration: InputDecoration(
                    labelText: s.barcode,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: AppColors.surface,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _purchasePriceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: s.purchasePrice,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: AppColors.surface,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _purchaseDateController,
                  decoration: InputDecoration(
                    labelText: s.purchaseDate,
                    hintText: 'YYYY-MM-DD',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: AppColors.surface,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _expiryDateController,
                  decoration: InputDecoration(
                    labelText: s.expiryDate,
                    hintText: 'YYYY-MM-DD',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: AppColors.surface,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _storeController,
                  decoration: InputDecoration(
                    labelText: s.store,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: AppColors.surface,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _serialController,
                  decoration: InputDecoration(
                    labelText: s.serial,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: AppColors.surface,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _tagsController,
                  decoration: InputDecoration(
                    labelText: s.tags,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: AppColors.surface,
                  ),
                ),
                const SizedBox(height: 16),
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
                FutureBuilder(
                  future: ref.read(categoriesRepositoryProvider).getAll(),
                  builder: (context, snap) {
                    final categories = snap.data ?? [];
                    return DropdownButtonFormField<int?>(
                      isExpanded: true,
                      value: _selectedCategoryId,
                      decoration: InputDecoration(
                        labelText: s.categories,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: AppColors.background,
                      ),
                      items: [
                        DropdownMenuItem<int?>(value: null, child: Text(s.noCategories)),
                        ...categories.map(
                          (c) => DropdownMenuItem<int?>(value: c.id, child: Text(c.name)),
                        ),
                      ],
                      onChanged: categories.isEmpty
                          ? null
                          : (v) => setState(() => _selectedCategoryId = v),
                    );
                  },
                ),
                FutureBuilder(
                  future: ref.read(categoriesRepositoryProvider).getAll(),
                  builder: (context, snap) {
                    if ((snap.data ?? []).isNotEmpty) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        s.noCategories,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                FutureBuilder(
                  future: ref.read(locationsRepositoryProvider).getAll(),
                  builder: (context, snap) {
                    final locations = snap.data ?? [];
                    return DropdownButtonFormField<int?>(
                      isExpanded: true,
                      value: _selectedLocationId,
                      decoration: InputDecoration(
                        labelText: s.selectLocation,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: AppColors.background,
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
