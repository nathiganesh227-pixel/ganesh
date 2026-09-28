import '../models/partner_models.dart';

abstract class PartnerRepository {
  // Onboarding & Profile
  Future<PartnerProfile> onboardPartner({
    required String legalName,
    required String displayName,
    required PartnerType partnerType,
    required String email,
    required String phone,
    required String city,
    required String state,
    required String address,
    required String pinCode,
    String? website,
    String? gstNumber,
    String? panNumber,
  });

  Future<PartnerProfile> getPartnerProfile(String partnerId);
  Future<PartnerProfile> updatePartnerProfile(String partnerId, Map<String, dynamic> data);

  // Documents (Gate 1)
  Future<PartnerDocument> uploadDocument(
    String partnerId, {
    required String documentType,
    required String fileUrl,
    required String fileName,
    int? fileSize,
  });
  Future<List<PartnerDocument>> getDocuments(String partnerId);
  Future<PartnerProfile> submitForReview(String partnerId);

  // Business Listings & Gates (Gate 2)
  Future<List<PartnerBusinessListing>> getBusinesses(String partnerId);
  Future<PartnerBusinessListing> createListing(
    String partnerId, {
    required String vertical,
    required String name,
    required String description,
    required String address,
    required String city,
    required String contactPhone,
    required String contactEmail,
    Map<String, dynamic>? metadata,
  });
  Future<PartnerBusinessListing> submitListingForReview(String partnerId, String businessId);
  Future<bool> publishListing(String partnerId, String businessId);
  Future<bool> unpublishListing(String partnerId, String businessId);

  // Bookings & Fulfillment
  Future<List<dynamic>> getBookings(String partnerId, {String? status});
  Future<bool> checkInCustomer(String partnerId, String bookingId);

  // Staff Management
  Future<List<PartnerStaffMember>> getStaff(String partnerId);
  Future<bool> inviteStaff(String partnerId, {required String email, required String role});
  Future<bool> removeStaff(String partnerId, String userId);

  // Payout Profile
  Future<PartnerPayoutProfile> getPayoutProfile(String partnerId);
  Future<PartnerPayoutProfile> updatePayoutProfile(
    String partnerId, {
    required String accountHolderName,
    required String bankName,
    required String accountNumber,
    required String ifscCode,
  });

  // Dashboard Overview
  Future<PartnerDashboardOverview> getDashboardOverview(String partnerId);

  // PLAZA Admin Governance
  Future<List<PartnerProfile>> adminListPartners({String? status, String? type});
  Future<Map<String, dynamic>> adminGetPartnerDetails(String partnerId);
  Future<bool> adminReviewPartner(String partnerId, {required String action, String? reason});
  Future<bool> adminSuspendPartner(String partnerId, {required String reason});
  Future<bool> adminResumePartner(String partnerId);
  Future<bool> adminReviewDocument(String partnerId, String docId, {required String action, String? reason});
  Future<bool> adminReviewListing(String partnerId, String businessId, {required String action, String? reason});
}
