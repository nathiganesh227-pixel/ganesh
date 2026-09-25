import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/models/admin_models.dart';
import '../../../core/repositories/admin_repository.dart';
import '../../../core/repositories/api_admin_repository.dart';
import '../../../core/widgets/glass_card.dart';

class AdminVerticalCatalogView extends StatefulWidget {
  final String vertical; // 'dining', 'events', 'activities', 'shopping', 'stays', 'sports'
  final String title;
  final String description;
  final IconData icon;
  final Color accentColor;
  final AdminRepository? repository;

  const AdminVerticalCatalogView({
    super.key,
    required this.vertical,
    required this.title,
    required this.description,
    required this.icon,
    required this.accentColor,
    this.repository,
  });

  @override
  State<AdminVerticalCatalogView> createState() => _AdminVerticalCatalogViewState();
}

class _AdminVerticalCatalogViewState extends State<AdminVerticalCatalogView> {
  late final AdminRepository _repo;
  List<AdminCatalogItem> _items = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? ApiAdminRepository();
    _loadItems();
  }

  @override
  void didUpdateWidget(covariant AdminVerticalCatalogView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.vertical != widget.vertical) {
      _loadItems();
    }
  }

  Future<void> _loadItems() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final res = await _repo.getVerticalItems(widget.vertical);
    if (!mounted) return;

    if (res.success && res.data != null) {
      setState(() {
        _items = res.data!;
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage = res.message ?? 'Failed to load ${widget.title} items.';
        _isLoading = false;
      });
    }
  }

  void _showAddOrEditDialog([AdminCatalogItem? existing]) {
    final nameController = TextEditingController(text: existing?.nameOrTitle ?? '');
    final tagController = TextEditingController(text: existing?.tagline ?? '');
    final catController = TextEditingController(text: existing?.category ?? '');
    final locController = TextEditingController(text: existing?.location ?? '');
    final priceController = TextEditingController(text: existing?.price?.toString() ?? '1500');
    final imgController = TextEditingController(text: existing?.imageUrl ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          existing == null ? 'Add to ${widget.title}' : 'Edit Item',
          style: AppTypography.headingMedium,
        ),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  style: AppTypography.bodyMedium,
                  decoration: InputDecoration(
                    labelText: widget.vertical == 'dining'
                        ? 'Restaurant Name'
                        : widget.vertical == 'shopping'
                            ? 'Product Name'
                            : 'Title / Experience Name',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: tagController,
                  style: AppTypography.bodyMedium,
                  decoration: InputDecoration(
                    labelText: widget.vertical == 'shopping' ? 'Brand Name' : 'Tagline / Short Intro',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: catController,
                        style: AppTypography.bodyMedium,
                        decoration: const InputDecoration(labelText: 'Category'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: priceController,
                        keyboardType: TextInputType.number,
                        style: AppTypography.bodyMedium,
                        decoration: InputDecoration(
                          labelText: widget.vertical == 'dining'
                              ? 'Price for Two (₹)'
                              : widget.vertical == 'stays'
                                  ? 'Starting / Night (₹)'
                                  : 'Price (₹)',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: locController,
                  style: AppTypography.bodyMedium,
                  decoration: const InputDecoration(labelText: 'Location / Venue Address'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: imgController,
                  style: AppTypography.bodyMedium,
                  decoration: const InputDecoration(labelText: 'Cover Image URL'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) return;

              Navigator.of(ctx).pop();
              final price = double.tryParse(priceController.text) ?? 1000.0;
              final img = imgController.text.trim().isNotEmpty
                  ? imgController.text.trim()
                  : 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4';

              final dto = <String, dynamic>{
                if (widget.vertical == 'dining' || widget.vertical == 'shopping' || widget.vertical == 'stays' || widget.vertical == 'sports')
                  'name': name
                else
                  'title': name,
                'tagline': tagController.text.trim(),
                'about': tagController.text.trim(),
                'description': tagController.text.trim(),
                'category': catController.text.trim().isEmpty ? 'General' : catController.text.trim(),
                'location': locController.text.trim().isEmpty ? 'Hyderabad' : locController.text.trim(),
                'venue': locController.text.trim().isEmpty ? 'Hyderabad Venue' : locController.text.trim(),
                'coverImageUrl': img,
                'posterUrl': img,
                'galleryImages': [img],
                'rating': existing?.rating ?? 4.8,
              };

              // Vertical-specific pricing keys
              if (widget.vertical == 'dining') {
                dto['priceForTwo'] = price;
                dto['cuisines'] = ['Multi-Cuisine'];
              } else if (widget.vertical == 'stays') {
                dto['startingPricePerNight'] = price;
              } else if (widget.vertical == 'sports') {
                dto['startingPricePerHour'] = price;
                dto['supportedSports'] = ['Multi-Sport'];
              } else {
                dto['price'] = price;
              }

              if (existing == null) {
                await _repo.createVerticalItem(widget.vertical, dto);
              } else {
                await _repo.updateVerticalItem(widget.vertical, existing.id, dto);
              }
              _loadItems();
            },
            style: ElevatedButton.styleFrom(backgroundColor: widget.accentColor),
            child: Text(existing == null ? 'Create Item' : 'Save Changes'),
          ),
        ],
      ),
    );
  }

  void _confirmTogglePublish(AdminCatalogItem item) {
    final willUnpublish = item.isPublished;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          willUnpublish ? 'Unpublish Item?' : 'Publish Item Live?',
          style: AppTypography.headingMedium,
        ),
        content: Text(
          willUnpublish
              ? 'Unpublishing "${item.nameOrTitle}" will immediately remove it from consumer-facing discovery, category lists, and unified search results. The data remains preserved in the administrative database.'
              : 'Publishing "${item.nameOrTitle}" will make it live and discoverable to all PLAZA consumers across catalog listings and search.',
          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final res = willUnpublish
                  ? await _repo.unpublishVerticalItem(widget.vertical, item.id)
                  : await _repo.publishVerticalItem(widget.vertical, item.id);

              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    res.success
                        ? willUnpublish
                            ? 'Item unpublished from consumer view.'
                            : 'Item successfully published live! ✨'
                        : res.message ?? 'Action failed.',
                  ),
                  backgroundColor: AppColors.surfaceElevated,
                ),
              );
              _loadItems();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: willUnpublish ? AppColors.warningOrange : AppColors.liveGreen,
              foregroundColor: Colors.white,
            ),
            child: Text(willUnpublish ? 'Unpublish' : 'Publish Live'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(AdminCatalogItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete "${item.nameOrTitle}"?', style: AppTypography.headingMedium),
        content: Text(
          'Are you sure you want to permanently delete this catalog item? This action is irreversible.',
          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final res = await _repo.deleteVerticalItem(widget.vertical, item.id);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(res.message ?? 'Item deleted successfully.'),
                  backgroundColor: AppColors.surfaceElevated,
                ),
              );
              _loadItems();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.alertRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _items.where((i) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return i.nameOrTitle.toLowerCase().contains(q) ||
          (i.category?.toLowerCase().contains(q) ?? false) ||
          (i.location?.toLowerCase().contains(q) ?? false);
    }).toList();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title, style: AppTypography.headingLarge),
                    const SizedBox(height: 4),
                    Text(
                      widget.description,
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddOrEditDialog(),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add Item'),
                style: ElevatedButton.styleFrom(backgroundColor: widget.accentColor),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Search bar
          TextField(
            onChanged: (val) => setState(() => _searchQuery = val),
            style: AppTypography.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Search by title, category, or location...',
              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
              filled: true,
              fillColor: AppColors.surfaceElevated,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.glassBorder),
              ),
            ),
          ),
          const SizedBox(height: 18),

          if (_isLoading)
            const Center(child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(color: AppColors.primary),
            ))
          else if (_errorMessage != null)
            Center(
              child: GlassCard(
                padding: const EdgeInsets.all(20),
                child: Text(_errorMessage!, style: const TextStyle(color: AppColors.alertRed)),
              ),
            )
          else if (filtered.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Text('No catalog entries found.', style: AppTypography.bodyMedium),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = filtered[index];
                return GlassCard(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          width: 56,
                          height: 56,
                          color: AppColors.surfaceElevated,
                          child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                              ? Image.network(
                                  item.imageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => Icon(widget.icon, color: widget.accentColor),
                                )
                              : Icon(widget.icon, color: widget.accentColor),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item.nameOrTitle,
                                    style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // PUBLISHED / UNPUBLISHED BADGE
                                InkWell(
                                  onTap: () => _confirmTogglePublish(item),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: item.isPublished
                                          ? AppColors.liveGreen.withValues(alpha: 0.15)
                                          : AppColors.warningOrange.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: item.isPublished
                                            ? AppColors.liveGreen.withValues(alpha: 0.3)
                                            : AppColors.warningOrange.withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          item.isPublished
                                              ? Icons.check_circle_outline_rounded
                                              : Icons.visibility_off_outlined,
                                          size: 12,
                                          color: item.isPublished ? AppColors.liveGreen : AppColors.warningOrange,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          item.isPublished ? 'Published' : 'Unpublished',
                                          style: TextStyle(
                                            color: item.isPublished ? AppColors.liveGreen : AppColors.warningOrange,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${item.category ?? "General"}${item.location != null ? " • ${item.location}" : ""}${item.price != null ? " • ₹${item.price!.toInt()}" : ""}',
                              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textSecondary),
                        onPressed: () => _showAddOrEditDialog(item),
                        tooltip: 'Edit Item',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.alertRed),
                        onPressed: () => _confirmDelete(item),
                        tooltip: 'Delete Item',
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
