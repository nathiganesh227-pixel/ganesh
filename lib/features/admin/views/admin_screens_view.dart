import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/models/admin_models.dart';
import '../../../core/repositories/admin_repository.dart';
import '../../../core/repositories/api_admin_repository.dart';
import '../../../core/widgets/glass_card.dart';

class AdminScreensView extends StatefulWidget {
  final AdminRepository? repository;

  const AdminScreensView({super.key, this.repository});

  @override
  State<AdminScreensView> createState() => _AdminScreensViewState();
}

class _AdminScreensViewState extends State<AdminScreensView> {
  late final AdminRepository _repo;
  List<AdminTheatre> _theatres = [];
  List<AdminScreen> _screens = [];
  String? _selectedTheatreId;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? ApiAdminRepository();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final theatresRes = await _repo.getTheatres();
    if (!mounted) return;

    if (theatresRes.success && theatresRes.data != null) {
      _theatres = theatresRes.data!;
      if (_theatres.isNotEmpty && _selectedTheatreId == null) {
        _selectedTheatreId = _theatres.first.id;
      }
    }

    final screensRes = await _repo.getScreens(theatreId: _selectedTheatreId);
    if (!mounted) return;

    if (screensRes.success && screensRes.data != null) {
      setState(() {
        _screens = screensRes.data!;
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage = screensRes.message ?? 'Failed to load screens.';
        _isLoading = false;
      });
    }
  }

  void _showAddScreenDialog([AdminScreen? existing]) {
    String selectedThId = existing?.theatreId ?? (_theatres.isNotEmpty ? _theatres.first.id : '');
    final nameController = TextEditingController(text: existing?.name ?? '');
    final typeController = TextEditingController(text: existing?.screenType ?? 'IMAX 3D');
    final capController = TextEditingController(text: existing?.capacity.toString() ?? '250');
    bool isActive = existing?.isActive ?? true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          backgroundColor: AppColors.surfaceCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(existing == null ? 'Add Screen to Theatre' : 'Edit Screen', style: AppTypography.headingMedium),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (existing == null && _theatres.isNotEmpty) ...[
                    DropdownButtonFormField<String>(
                      initialValue: selectedThId,
                      dropdownColor: AppColors.surfaceElevated,
                      style: AppTypography.bodyMedium,
                      decoration: const InputDecoration(labelText: 'Theatre Multiplex'),
                      items: _theatres.map((t) {
                        return DropdownMenuItem(value: t.id, child: Text(t.name));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setDlgState(() => selectedThId = val);
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    controller: nameController,
                    style: AppTypography.bodyMedium,
                    decoration: const InputDecoration(labelText: 'Screen Name (e.g. Audi 1 / Screen 2)'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: typeController,
                          style: AppTypography.bodyMedium,
                          decoration: const InputDecoration(labelText: 'Screen Type (e.g. IMAX 3D)'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: capController,
                          keyboardType: TextInputType.number,
                          style: AppTypography.bodyMedium,
                          decoration: const InputDecoration(labelText: 'Capacity (Seats)'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SwitchListTile(
                    title: Text('Screen Operational', style: AppTypography.bodySmall),
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
                final capacity = int.tryParse(capController.text) ?? 100;
                if (name.isEmpty || capacity <= 0) return;

                Navigator.of(ctx).pop();
                final dto = {
                  'name': name,
                  'screenType': typeController.text.trim().isEmpty ? 'standard' : typeController.text.trim(),
                  'capacity': capacity,
                  'isActive': isActive,
                };

                if (existing == null) {
                  await _repo.createScreen(selectedThId, dto);
                } else {
                  await _repo.updateScreen(existing.id, dto);
                }
                _loadData();
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: Text(existing == null ? 'Add Screen' : 'Save Changes'),
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
                    Text('Audi & Screen Management', style: AppTypography.headingLarge),
                    const SizedBox(height: 4),
                    Text(
                      'Configure screens, seating capacities, and formats for show scheduling.',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddScreenDialog(),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add Screen'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Filter by Theatre
          if (_theatres.isNotEmpty)
            Row(
              children: [
                Text('Filter by Multiplex: ', style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted)),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.glassBorder),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedTheatreId,
                        dropdownColor: AppColors.surfaceElevated,
                        style: AppTypography.bodyMedium,
                        items: [
                          const DropdownMenuItem(value: null, child: Text('All Theatres')),
                          ..._theatres.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name))),
                        ],
                        onChanged: (val) {
                          setState(() => _selectedTheatreId = val);
                          _loadData();
                        },
                      ),
                    ),
                  ),
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
          else if (_screens.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Text('No screens found for the selected multiplex.', style: AppTypography.bodyMedium),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _screens.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final scr = _screens[index];
                final theatreName = _theatres.firstWhere((t) => t.id == scr.theatreId, orElse: () => AdminTheatre(id: '', name: 'Theatre', location: '')).name;

                return GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryIndigo.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.tv_rounded, color: AppColors.secondaryIndigo, size: 24),
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
                                    scr.name,
                                    style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.secondaryCyan.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    scr.screenType,
                                    style: const TextStyle(
                                      color: AppColors.secondaryCyan,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$theatreName • Capacity: ${scr.capacity} Seats',
                              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textSecondary),
                        onPressed: () => _showAddScreenDialog(scr),
                        tooltip: 'Edit Screen',
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
