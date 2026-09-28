import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/models/partner_models.dart';
import '../../../core/repositories/partner_repository.dart';
import '../../../core/repositories/api_partner_repository.dart';

class PartnerOnboardingSheet extends StatefulWidget {
  final PartnerRepository? repository;
  final VoidCallback? onCompleted;

  const PartnerOnboardingSheet({
    super.key,
    this.repository,
    this.onCompleted,
  });

  static Future<void> show(BuildContext context, {PartnerRepository? repository, VoidCallback? onCompleted}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PartnerOnboardingSheet(
        repository: repository,
        onCompleted: onCompleted,
      ),
    );
  }

  @override
  State<PartnerOnboardingSheet> createState() => _PartnerOnboardingSheetState();
}

class _PartnerOnboardingSheetState extends State<PartnerOnboardingSheet> {
  late final PartnerRepository _repository;
  int _currentStep = 0;
  bool _isLoading = false;
  String? _errorMessage;

  // Step 1: Partner Type
  PartnerType _selectedType = PartnerType.restaurant;

  // Step 2 & 3: Business Information
  final _legalNameController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController(text: 'Hyderabad');
  final _stateController = TextEditingController(text: 'Telangana');
  final _addressController = TextEditingController();
  final _pinCodeController = TextEditingController(text: '500081');
  final _gstController = TextEditingController();
  final _panController = TextEditingController();

  // Created partner ID after Step 3
  PartnerProfile? _createdPartner;

  // Step 4: Documents Uploaded
  final List<Map<String, String>> _uploadedDocs = [];

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? ApiPartnerRepository();
  }

  @override
  void dispose() {
    _legalNameController.dispose();
    _displayNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _addressController.dispose();
    _pinCodeController.dispose();
    _gstController.dispose();
    _panController.dispose();
    super.dispose();
  }

  Future<void> _handleNextStep() async {
    setState(() => _errorMessage = null);

    if (_currentStep == 0) {
      // Advance to step 1 (Basic Info)
      setState(() => _currentStep = 1);
      return;
    }

    if (_currentStep == 1) {
      if (_legalNameController.text.trim().isEmpty ||
          _displayNameController.text.trim().isEmpty ||
          _emailController.text.trim().isEmpty ||
          _phoneController.text.trim().isEmpty) {
        setState(() => _errorMessage = 'Please complete all required identity fields.');
        return;
      }
      setState(() => _currentStep = 2);
      return;
    }

    if (_currentStep == 2) {
      if (_addressController.text.trim().isEmpty || _pinCodeController.text.trim().isEmpty) {
        setState(() => _errorMessage = 'Please provide valid business location details.');
        return;
      }

      setState(() => _isLoading = true);
      try {
        final profile = await _repository.onboardPartner(
          legalName: _legalNameController.text.trim(),
          displayName: _displayNameController.text.trim(),
          partnerType: _selectedType,
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          city: _cityController.text.trim(),
          state: _stateController.text.trim(),
          address: _addressController.text.trim(),
          pinCode: _pinCodeController.text.trim(),
          gstNumber: _gstController.text.trim().isNotEmpty ? _gstController.text.trim() : null,
          panNumber: _panController.text.trim().isNotEmpty ? _panController.text.trim() : null,
        );

        setState(() {
          _createdPartner = profile;
          _currentStep = 3;
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Onboarding failed: $e';
        });
      }
      return;
    }

    if (_currentStep == 3) {
      if (_uploadedDocs.isEmpty) {
        setState(() => _errorMessage = 'Please upload at least one required KYC document.');
        return;
      }

      setState(() => _isLoading = true);
      try {
        if (_createdPartner != null) {
          final submitted = await _repository.submitForReview(_createdPartner!.id);
          setState(() {
            _createdPartner = submitted;
            _currentStep = 4;
            _isLoading = false;
          });
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Submission failed: $e';
        });
      }
      return;
    }

    if (_currentStep == 4) {
      Navigator.of(context).pop();
      widget.onCompleted?.call();
    }
  }

  void _simulateUploadDocument(String docType, String docTitle) async {
    if (_createdPartner == null) return;
    setState(() => _isLoading = true);

    try {
      final doc = await _repository.uploadDocument(
        _createdPartner!.id,
        documentType: docType,
        fileUrl: 'https://cdn.plaza.app/docs/${docType}_sample.pdf',
        fileName: '$docTitle.pdf',
        fileSize: 1048576,
      );

      setState(() {
        _uploadedDocs.add({'type': docType, 'name': '$docTitle.pdf', 'status': doc.status});
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _uploadedDocs.add({'type': docType, 'name': '$docTitle.pdf', 'status': 'pending'});
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: AppColors.backgroundDark,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: AppColors.cardBorder.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Partner with PLAZA',
                      style: AppTypography.headingMedium.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Step ${_currentStep + 1} of 5 • ${_getStepTitle()}',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.accentGold),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          // Progress line
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: LinearProgressIndicator(
              value: (_currentStep + 1) / 5,
              backgroundColor: Colors.white12,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentGold),
              minHeight: 3,
            ),
          ),
          if (_errorMessage != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
              ),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 13),
              ),
            ),
          // Body content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: _buildCurrentStepContent(),
            ),
          ),
          // Action button footer
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              border: Border(top: BorderSide(color: AppColors.cardBorder.withValues(alpha: 0.3))),
            ),
            child: Row(
              children: [
                if (_currentStep > 0 && _currentStep < 4)
                  OutlinedButton(
                    onPressed: _isLoading ? null : () => setState(() => _currentStep--),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Colors.white24),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    ),
                    child: const Text('Back'),
                  ),
                if (_currentStep > 0 && _currentStep < 4) const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleNextStep,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentGold,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                          )
                        : Text(
                            _currentStep == 4 ? 'Go to Partner Console' : (_currentStep == 3 ? 'Submit for Review' : 'Continue'),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 0:
        return 'Business Type';
      case 1:
        return 'Identity & Contact';
      case 2:
        return 'Business Location';
      case 3:
        return 'KYC Documents';
      case 4:
        return 'Under Review';
      default:
        return '';
    }
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStep0TypeSelection();
      case 1:
        return _buildStep1Identity();
      case 2:
        return _buildStep2Location();
      case 3:
        return _buildStep3Documents();
      case 4:
        return _buildStep4ReviewPending();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStep0TypeSelection() {
    final types = [
      {'type': PartnerType.restaurant, 'title': 'Restaurant & Dining', 'desc': 'Fine dining, cafes, lounges, table reservations', 'icon': Icons.restaurant_rounded},
      {'type': PartnerType.eventOrganizer, 'title': 'Event Organizer', 'desc': 'Concerts, festivals, conferences, comedy shows', 'icon': Icons.celebration_rounded},
      {'type': PartnerType.activityOperator, 'title': 'Activity Operator', 'desc': 'Go-karting, bowling, escape rooms, theme parks', 'icon': Icons.local_activity_rounded},
      {'type': PartnerType.hotel, 'title': 'Hotel / Resort / Stay', 'desc': 'Luxury suites, boutique stays, resort villas', 'icon': Icons.hotel_rounded},
      {'type': PartnerType.sportsVenue, 'title': 'Sports Venue', 'desc': 'Badminton courts, box cricket, turf arenas', 'icon': Icons.sports_tennis_rounded},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Your Business Category',
          style: AppTypography.headingSmall.copyWith(color: Colors.white),
        ),
        const SizedBox(height: 8),
        Text(
          'Join India’s premier lifestyle super app and reach millions of verified customers.',
          style: AppTypography.bodySmall.copyWith(color: Colors.white60),
        ),
        const SizedBox(height: 20),
        ...types.map((item) {
          final type = item['type'] as PartnerType;
          final isSelected = _selectedType == type;

          return GestureDetector(
            onTap: () => setState(() => _selectedType = type),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.accentGold.withValues(alpha: 0.12) : AppColors.cardDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? AppColors.accentGold : AppColors.cardBorder.withValues(alpha: 0.4),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.accentGold : Colors.white10,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      item['icon'] as IconData,
                      color: isSelected ? Colors.black : Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['title'] as String,
                          style: AppTypography.bodyLarge.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item['desc'] as String,
                          style: AppTypography.bodySmall.copyWith(color: Colors.white60),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                    color: isSelected ? AppColors.accentGold : Colors.white30,
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildStep1Identity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Business Identity & Credentials', style: AppTypography.headingSmall.copyWith(color: Colors.white)),
        const SizedBox(height: 6),
        Text('Provide your registered business details for verification.', style: AppTypography.bodySmall.copyWith(color: Colors.white60)),
        const SizedBox(height: 20),
        _buildTextField('Legal Entity Name *', _legalNameController, 'e.g. Spice Garden Hospitality Pvt Ltd'),
        const SizedBox(height: 14),
        _buildTextField('Brand / Customer Display Name *', _displayNameController, 'e.g. Spice Garden Fine Dining'),
        const SizedBox(height: 14),
        _buildTextField('Business Email Address *', _emailController, 'owner@business.com', keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 14),
        _buildTextField('Business Phone Number *', _phoneController, '+91 98765 00000', keyboardType: TextInputType.phone),
        const SizedBox(height: 14),
        _buildTextField('GSTIN (Tax ID)', _gstController, 'e.g. 36AABCS1429B1Z1'),
        const SizedBox(height: 14),
        _buildTextField('PAN Number', _panController, 'e.g. AABCS1429B'),
      ],
    );
  }

  Widget _buildStep2Location() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Location & Operating City', style: AppTypography.headingSmall.copyWith(color: Colors.white)),
        const SizedBox(height: 6),
        Text('Where customers will discover and visit your venue.', style: AppTypography.bodySmall.copyWith(color: Colors.white60)),
        const SizedBox(height: 20),
        _buildTextField('Registered Physical Address *', _addressController, 'Building, Street, Landmark', maxLines: 2),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: _buildTextField('City *', _cityController, 'Hyderabad')),
            const SizedBox(width: 12),
            Expanded(child: _buildTextField('State *', _stateController, 'Telangana')),
          ],
        ),
        const SizedBox(height: 14),
        _buildTextField('PIN Code *', _pinCodeController, '500081', keyboardType: TextInputType.number),
      ],
    );
  }

  Widget _buildStep3Documents() {
    final docRecommendations = _getDocTypesForVertical(_selectedType);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('KYC Verification Documents', style: AppTypography.headingSmall.copyWith(color: Colors.white)),
        const SizedBox(height: 6),
        Text('Gate 1 Verification: Upload business license and identity documents.', style: AppTypography.bodySmall.copyWith(color: Colors.white60)),
        const SizedBox(height: 20),
        ...docRecommendations.map((doc) {
          final isUploaded = _uploadedDocs.any((u) => u['type'] == doc['type']);
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isUploaded ? Colors.greenAccent.withValues(alpha: 0.5) : AppColors.cardBorder.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                Icon(
                  isUploaded ? Icons.verified_rounded : Icons.description_outlined,
                  color: isUploaded ? Colors.greenAccent : AppColors.accentGold,
                  size: 28,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(doc['title']!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      Text(doc['desc']!, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: isUploaded ? null : () => _simulateUploadDocument(doc['type']!, doc['title']!),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isUploaded ? Colors.white10 : AppColors.accentGold.withValues(alpha: 0.2),
                    foregroundColor: isUploaded ? Colors.white54 : AppColors.accentGold,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                  child: Text(isUploaded ? 'Uploaded' : 'Upload'),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildStep4ReviewPending() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 20),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.accentGold.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.accentGold, width: 2),
          ),
          child: const Icon(Icons.hourglass_top_rounded, color: AppColors.accentGold, size: 40),
        ),
        const SizedBox(height: 24),
        Text('Submission Received', style: AppTypography.headingSmall.copyWith(color: Colors.white)),
        const SizedBox(height: 8),
        Text(
          'Your partner organization application has been submitted for PLAZA Admin review (Gate 1).',
          textAlign: TextAlign.center,
          style: AppTypography.bodyMedium.copyWith(color: Colors.white70),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder.withValues(alpha: 0.4)),
          ),
          child: Column(
            children: [
              _buildInfoRow('Organization', _createdPartner?.displayName ?? _displayNameController.text),
              const Divider(color: Colors.white12, height: 20),
              _buildInfoRow('Category', _selectedType.displayName),
              const Divider(color: Colors.white12, height: 20),
              _buildInfoRow('Status', 'UNDER REVIEW', valueColor: AppColors.accentGold),
              const Divider(color: Colors.white12, height: 20),
              _buildInfoRow('Gate 1 Verification', 'PLAZA Admin Review in Progress'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, String hint, {TextInputType? keyboardType, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white30),
            filled: true,
            fillColor: AppColors.cardDark,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.cardBorder.withValues(alpha: 0.5))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.accentGold)),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {Color valueColor = Colors.white}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13)),
        Text(value, style: TextStyle(color: valueColor, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }

  List<Map<String, String>> _getDocTypesForVertical(PartnerType type) {
    switch (type) {
      case PartnerType.restaurant:
        return [
          {'type': 'fssai_license', 'title': 'FSSAI Food License *', 'desc': 'Mandatory for food safety verification'},
          {'type': 'gst_certificate', 'title': 'GSTIN Registration', 'desc': 'Official tax identification certificate'},
          {'type': 'pan_card', 'title': 'Business PAN Card', 'desc': 'PAN copy of legal business entity'},
        ];
      case PartnerType.eventOrganizer:
        return [
          {'type': 'incorporation_cert', 'title': 'Company Incorporation *', 'desc': 'Certificate of Incorporation / Registration'},
          {'type': 'gst_certificate', 'title': 'GSTIN Certificate', 'desc': 'GST tax registration document'},
          {'type': 'safety_clearance', 'title': 'Venue / Event Safety Clearance', 'desc': 'Event safety certification'},
        ];
      case PartnerType.activityOperator:
        return [
          {'type': 'safety_permit', 'title': 'Safety & Equipment Permit *', 'desc': 'Inspected safety standard documentation'},
          {'type': 'liability_insurance', 'title': 'Commercial Liability Insurance', 'desc': 'Customer accident insurance policy'},
          {'type': 'gst_certificate', 'title': 'GST Certificate', 'desc': 'Tax registration certificate'},
        ];
      case PartnerType.hotel:
        return [
          {'type': 'property_registration', 'title': 'Hotel Property Registration *', 'desc': 'Hospitality / Municipal trade license'},
          {'type': 'fire_safety_noc', 'title': 'Fire Safety NOC', 'desc': 'Fire department safety clearance'},
          {'type': 'gst_certificate', 'title': 'GST Registration (12% Bracket)', 'desc': 'Hospitality tax registration'},
        ];
      case PartnerType.sportsVenue:
        return [
          {'type': 'trade_license', 'title': 'Commercial Arena License *', 'desc': 'Municipal sports & recreational permit'},
          {'type': 'pan_card', 'title': 'Owner / Business PAN', 'desc': 'Identification for payout compliance'},
        ];
    }
  }
}
