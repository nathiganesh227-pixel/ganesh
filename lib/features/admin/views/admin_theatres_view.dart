import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/models/admin_models.dart';
import '../../../core/repositories/admin_repository.dart';
import '../../../core/repositories/api_admin_repository.dart';
import '../../../core/widgets/glass_card.dart';

class AdminTheatresView extends StatefulWidget {
  final AdminRepository? repository;

  const AdminTheatresView({super.key, this.repository});

  @override
  State<AdminTheatresView> createState() => _AdminTheatresViewState();
}

class _AdminTheatresViewState extends State<AdminTheatresView> {
  late final AdminRepository _repo;
  List<AdminTheatre> _theatres = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? ApiAdminRepository();
    _loadTheatres();
  }

  Future<void> _loadTheatres() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final res = await _repo.getTheatres();
    if (!mounted) return;

    if (res.success && res.data != null) {
      setState(() {
        _theatres = res.data!;
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage = res.message ?? 'Failed to load theatres.';
        _isLoading = false;
      });
    }
  }

  void _showTheatreDialog([AdminTheatre? existing]) {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final locationController = TextEditingController(text: existing?.location ?? '');
    final cityController = TextEditingController(text: existing?.city ?? 'Hyderabad');
    final addressController = TextEditingController(text: existing?.address ?? '');
    final distanceController = TextEditingController(text: existing?.distance ?? '2.5 km');
    bool isActive = existing?.isActive ?? true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          backgroundColor: AppColors.surfaceCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(existing == null ? 'Add Theatre Venue' : 'Edit Theatre', style: AppTypography.headingMedium),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    style: AppTypography.bodyMedium,
                    decoration: const InputDecoration(labelText: 'Theatre Name (e.g. AMB Cinemas)'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: locationController,
                    style: AppTypography.bodyMedium,
                    decoration: const InputDecoration(labelText: 'Location / Area (e.g. Gachibowli)'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: cityController,
                          style: AppTypography.bodyMedium,
                          decoration: const InputDecoration(labelText: 'City'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: distanceController,
                          style: AppTypography.bodyMedium,
                          decoration: const InputDecoration(labelText: 'Distance (e.g. 2.4 km)'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: addressController,
                    maxLines: 2,
                    style: AppTypography.bodyMedium,
                    decoration: const InputDecoration(labelText: 'Full Address'),
                  ),
                  const SizedBox(height: 14),
                  SwitchListTile(
                    title: Text('Operational / Active', style: AppTypography.bodySmall),
                    value: isActive,
                    activeThumbColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) => setDlgState(() => isActive = val),
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
                final location = locationController.text.trim();
                if (name.isEmpty || location.isEmpty) return;

                Navigator.of(ctx).pop();
                final dto = {
                  'name': name,
                  'location': location,
                  'city': cityController.text.trim().isEmpty ? 'Hyderabad' : cityController.text.trim(),
                  'address': addressController.text.trim(),
                  'distance': distanceController.text.trim(),
                  'isActive': isActive,
                  'amenities': ['Dolby Atmos', 'Laser Projection', 'VIP Lounge'],
                };

                if (existing == null) {
                  await _repo.createTheatre(dto);
                } else {
                  await _repo.updateTheatre(existing.id, dto);
                }
                _loadTheatres();
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: Text(existing == null ? 'Create Venue' : 'Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                    Text('Theatre Multiplexes & Venues', style: AppTypography.headingLarge),
                    const SizedBox(height: 4),
                    Text(
                      'Configure partner theatres, metro locations, and address details.',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showTheatreDialog(),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add Theatre'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 20),

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
          else if (_theatres.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Text('No theatres configured yet.', style: AppTypography.bodyMedium),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _theatres.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final t = _theatres[index];
                return GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.accentAmber.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.theaters_rounded, color: AppColors.accentAmber, size: 24),
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
                                    t.name,
                                    style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: t.isActive
                                        ? AppColors.liveGreen.withValues(alpha: 0.15)
                                        : AppColors.textMuted.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    t.isActive ? 'Active' : 'Inactive',
                                    style: TextStyle(
                                      color: t.isActive ? AppColors.liveGreen : AppColors.textMuted,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${t.city} • ${t.location}${t.distance != null ? ' • ${t.distance}' : ''}',
                              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, fontSize: 11),
                            ),
                            if (t.address != null && t.address!.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                t.address!,
                                style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted, fontSize: 10),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textSecondary),
                        onPressed: () => _showTheatreDialog(t),
                        tooltip: 'Edit Theatre',
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
