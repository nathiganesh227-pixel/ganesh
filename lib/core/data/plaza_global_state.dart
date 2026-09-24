import 'package:flutter/foundation.dart';
import '../models/unified_booking.dart';
import '../models/plan.dart';
import '../models/rewards.dart';
import '../models/notification.dart';
import '../models/movie.dart';
import '../models/movie_booking.dart';
import '../models/cinema_showtime.dart';
import '../models/cinema_seat.dart';
import '../models/dining.dart';
import '../models/event.dart';
import '../models/activity.dart';
import '../models/shopping.dart';
import '../models/stay.dart';
import '../models/sports.dart';
import 'movie_mock_data.dart';
import 'dining_mock_data.dart';
import 'event_mock_data.dart';
import 'activity_mock_data.dart';
import 'shopping_mock_data.dart';
import 'stay_mock_data.dart';
import 'sports_mock_data.dart';

class PlazaGlobalState extends ChangeNotifier {
  static final PlazaGlobalState instance = PlazaGlobalState._internal();

  factory PlazaGlobalState() {
    return instance;
  }

  PlazaGlobalState._internal() {
    _initializeSeedData();
  }

  // Profile data
  final String userName = 'Gopi Ganesh';
  final String userEmail = 'gopi.ganesh@plaza.club';
  final String userPhone = '+91 98765 43210';
  final String userTier = 'PLAZA Black Tier';
  final String membershipId = 'PLZ-BLK-88210';
  final String referralCode = 'PLAZA-GANESH';

  // State collections
  final List<UnifiedBooking> _bookings = [];
  final List<PlazaPlan> _savedPlans = [];
  final Set<String> _favoriteIds = {'mov_1', 'rest_1', 'act_1', 'hotel_1', 'sp_1'};
  final List<RecentlyViewedItem> _recentlyViewed = [];
  int _rewardsBalance = 2480;
  final List<RewardVoucher> _vouchers = [];
  final List<RewardTransaction> _rewardTransactions = [];
  final List<PlazaNotification> _notifications = [];

  // Getters
  List<UnifiedBooking> get bookings => List.unmodifiable(_bookings);
  List<PlazaPlan> get savedPlans => List.unmodifiable(_savedPlans);
  Set<String> get favoriteIds => Set.unmodifiable(_favoriteIds);
  List<RecentlyViewedItem> get recentlyViewed => List.unmodifiable(_recentlyViewed);
  int get rewardsBalance => _rewardsBalance;
  List<RewardVoucher> get vouchers => List.unmodifiable(_vouchers);
  List<RewardTransaction> get rewardTransactions => List.unmodifiable(_rewardTransactions);
  List<PlazaNotification> get notifications => List.unmodifiable(_notifications);

  int get unreadNotificationsCount =>
      _notifications.where((n) => !n.isRead).length;

  List<UnifiedBooking> get upcomingBookings =>
      _bookings.where((b) => b.status == BookingStatus.upcoming).toList();

  List<UnifiedBooking> get activeBookings =>
      _bookings.where((b) => b.status == BookingStatus.active).toList();

  List<UnifiedBooking> get completedBookings =>
      _bookings.where((b) => b.status == BookingStatus.completed).toList();

  List<UnifiedBooking> get cancelledBookings =>
      _bookings.where((b) => b.status == BookingStatus.cancelled).toList();

  // Booking management
  void addBooking(UnifiedBooking booking) {
    _bookings.insert(0, booking);
    _awardPoints((booking.totalAmount * 0.1).toInt(), 'Booking Confirmed: ${booking.title}');
    _notifications.insert(
      0,
      PlazaNotification(
        id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
        title: '${booking.type.displayName} Confirmed! 🎟️',
        message: 'Your booking for ${booking.title} has been confirmed.',
        timeAgo: 'Just now',
        category: PlazaNotificationCategory.bookings,
      ),
    );
    notifyListeners();
  }

  void cancelBooking(String bookingId) {
    final index = _bookings.indexWhere((b) => b.id == bookingId);
    if (index != -1) {
      final old = _bookings[index];
      _bookings[index] = old.copyWith(status: BookingStatus.cancelled);
      _notifications.insert(
        0,
        PlazaNotification(
          id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
          title: 'Booking Cancelled',
          message: '${old.title} booking has been cancelled and refund initiated.',
          timeAgo: 'Just now',
          category: PlazaNotificationCategory.bookings,
        ),
      );
      notifyListeners();
    }
  }

  // Plans management
  void savePlan(PlazaPlan plan) {
    final existingIndex = _savedPlans.indexWhere((p) => p.id == plan.id);
    if (existingIndex >= 0) {
      _savedPlans[existingIndex] = plan.copyWith(isSaved: true);
    } else {
      _savedPlans.insert(0, plan.copyWith(isSaved: true));
    }
    notifyListeners();
  }

  void removeSavedPlan(String planId) {
    _savedPlans.removeWhere((p) => p.id == planId);
    notifyListeners();
  }

  String bookEntirePlan(PlazaPlan plan) {
    final planBookingId = 'PLN-HYD-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    for (final item in plan.items) {
      final booking = UnifiedBooking(
        id: 'BK-${item.id.toUpperCase()}-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
        type: item.vertical,
        title: item.title,
        subtitle: '${item.venue} (${item.area})',
        location: item.area,
        date: plan.date,
        time: item.time,
        imageUrl: item.imageUrl,
        status: BookingStatus.upcoming,
        totalAmount: item.costPerPerson * plan.peopleCount,
        confirmationCode: 'QR-$planBookingId-${item.id}',
        seatOrSlotInfo: '${plan.peopleCount} Guests • ${item.time}',
      );
      _bookings.insert(0, booking);
    }

    _awardPoints(450, 'Book Entire Plan Bonus: ${plan.title}');
    _notifications.insert(
      0,
      PlazaNotification(
        id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Full Day Plan Booked! ✨',
        message: '${plan.title} (${plan.items.length} experiences) confirmed under Plan ID $planBookingId.',
        timeAgo: 'Just now',
        category: PlazaNotificationCategory.plans,
      ),
    );

    notifyListeners();
    return planBookingId;
  }

  // Favorites
  bool isFavorite(String id) => _favoriteIds.contains(id);

  void toggleFavorite(String id) {
    if (_favoriteIds.contains(id)) {
      _favoriteIds.remove(id);
    } else {
      _favoriteIds.add(id);
    }
    notifyListeners();
  }

  // Recently Viewed
  void addRecentlyViewed(RecentlyViewedItem item) {
    _recentlyViewed.removeWhere((x) => x.id == item.id);
    _recentlyViewed.insert(0, item);
    if (_recentlyViewed.length > 10) {
      _recentlyViewed.removeLast();
    }
    notifyListeners();
  }

  void clearRecentlyViewed() {
    _recentlyViewed.clear();
    notifyListeners();
  }

  // Rewards
  void _awardPoints(int pts, String reason) {
    if (pts <= 0) return;
    _rewardsBalance += pts;
    _rewardTransactions.insert(
      0,
      RewardTransaction(
        id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
        title: reason,
        description: 'Earned with PLAZA Experience',
        pointsChange: pts,
        timestamp: DateTime.now(),
        isCredit: true,
      ),
    );
  }

  bool redeemVoucher(String voucherId) {
    final index = _vouchers.indexWhere((v) => v.id == voucherId);
    if (index == -1) return false;
    final voucher = _vouchers[index];
    if (voucher.isRedeemed || _rewardsBalance < voucher.pointsCost) {
      return false;
    }

    _rewardsBalance -= voucher.pointsCost;
    _vouchers[index] = voucher.copyWith(isRedeemed: true);

    _rewardTransactions.insert(
      0,
      RewardTransaction(
        id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Voucher Redeemed: ${voucher.title}',
        description: 'Code: ${voucher.code}',
        pointsChange: voucher.pointsCost,
        timestamp: DateTime.now(),
        isCredit: false,
      ),
    );

    _notifications.insert(
      0,
      PlazaNotification(
        id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Reward Voucher Unlocked! 🎁',
        message: 'Use code ${voucher.code} to get ₹${voucher.discountAmount.toInt()} off.',
        timeAgo: 'Just now',
        category: PlazaNotificationCategory.rewards,
      ),
    );

    notifyListeners();
    return true;
  }

  // Notifications
  void markAllNotificationsAsRead() {
    for (int i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(isRead: true);
    }
    notifyListeners();
  }

  void markNotificationAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      notifyListeners();
    }
  }

  // Seed Data Initializer
  void _initializeSeedData() {
    final now = DateTime.now();

    // 1. Movie Booking Seed
    final sampleMovie = MovieMockData.movies.first;
    const sampleShowtime = ShowtimeSlot(
      id: 'st_1',
      time: '7:30 PM',
      format: MovieFormat.imax3D,
      language: 'English',
      screenName: 'IMAX Screen 1',
      basePrice: 450,
      isFillingFast: true,
    );
    final sampleSeats = [
      CinemaSeat(
        id: 'K_12',
        rowLabel: 'K',
        seatNumber: 12,
        tier: SeatTier.vip,
        price: 450,
        status: SeatStatus.selected,
      ),
      CinemaSeat(
        id: 'K_13',
        rowLabel: 'K',
        seatNumber: 13,
        tier: SeatTier.vip,
        price: 450,
        status: SeatStatus.selected,
      ),
    ];
    final sampleMovieBooking = MovieBooking(
      bookingId: 'PLZ-MOV-84920',
      movie: sampleMovie,
      theatre: const Theatre(
        id: 'th_1',
        name: 'AMB Cinemas, Gachibowli',
        location: 'Sarath City Capital Mall, Kondapur',
        distance: '3.2 km',
        amenities: ['IMAX with Laser', 'Dolby Atmos', 'Recliner Lounges', 'Valet Parking'],
        showtimes: [sampleShowtime],
      ),
      showtime: sampleShowtime,
      date: now.add(const Duration(hours: 3)),
      seats: sampleSeats,
      snacks: [],
      ticketTotal: 900,
      convenienceFee: 70,
      taxes: 18,
      discountAmount: 0,
      grandTotal: 988,
      paymentMethod: 'Apple Pay / UPI',
      bookedAt: now.subtract(const Duration(hours: 2)),
    );

    // 2. Dining Booking Seed
    final sampleRestaurant = DiningMockData.restaurants.first;
    final sampleDiningReservation = DiningReservation(
      reservationId: 'PLZ-DIN-38102',
      restaurant: sampleRestaurant,
      date: now.add(const Duration(days: 1)),
      timeSlot: '8:30 PM',
      partySize: 2,
      seatingPreference: SeatingPreference.outdoor,
      specialRequest: 'Window table with anniversary candle',
      guestName: 'Gopi Ganesh',
      guestPhone: '+91 98765 43210',
      createdAt: now.subtract(const Duration(hours: 1)),
    );

    // 3. Event Booking Seed
    final sampleEvent = EventMockData.events.first;
    final sampleEventBooking = EventBooking(
      bookingId: 'PLZ-EVT-77201',
      event: sampleEvent,
      date: now.add(const Duration(days: 4)),
      ticketTier: sampleEvent.ticketTiers.first,
      quantity: 2,
      subtotal: sampleEvent.ticketTiers.first.price * 2,
      platformFee: 80,
      taxes: 45,
      discountAmount: 0,
      grandTotal: (sampleEvent.ticketTiers.first.price * 2) + 125,
      paymentMethod: 'PLAZA Pay / UPI',
      bookedAt: now.subtract(const Duration(days: 1)),
    );

    // 4. Activity Booking Seed (Active Now!)
    final sampleActivity = ActivityMockData.activities.first;
    final sampleActivityBooking = ActivityBooking(
      bookingId: 'PLZ-ACT-19402',
      activity: sampleActivity,
      date: now,
      timeSlot: 'Now - 6:00 PM',
      numberOfPeople: 3,
      package: sampleActivity.packages.first,
      addOns: [],
      subtotal: sampleActivity.packages.first.pricePerPerson * 3,
      platformFee: 60,
      taxes: 35,
      discountAmount: 0,
      grandTotal: (sampleActivity.packages.first.pricePerPerson * 3) + 95,
      paymentMethod: 'UPI AutoPay',
      isSharedGroupBooking: true,
      bookedAt: now.subtract(const Duration(minutes: 40)),
    );

    // 5. Shopping Order Seed (Completed)
    final sampleProduct = ShoppingMockData.products.first;
    final sampleShoppingOrder = ShoppingOrder(
      orderId: 'ORD-PLZ-83912',
      items: [
        CartItem(product: sampleProduct, quantity: 1),
      ],
      itemsTotal: sampleProduct.price,
      discountAmount: 200,
      platformFee: 29,
      gstAmount: 90,
      grandTotal: sampleProduct.price - 200 + 119,
      fulfillmentType: ShoppingFulfillmentType.inStorePickup,
      storeName: 'Rare Rabbit Flagship',
      storeLocation: 'Inorbit Mall Hitec City, Store Pickup Counter',
      orderTime: now.subtract(const Duration(days: 3)),
      qrCodeData: 'ORD-PLZ-83912-PICKUP',
      paymentMethod: 'Credit Card (Apple Pay)',
      pickupCode: 'RR-83912',
    );

    // 6. Stay Booking Seed (Completed)
    final sampleHotel = StayMockData.hotels.first;
    final sampleStayBooking = HotelBooking(
      bookingId: 'PLZ-STY-44019',
      hotel: sampleHotel,
      roomType: sampleHotel.roomTypes.first,
      checkInDate: now.subtract(const Duration(days: 10)),
      checkOutDate: now.subtract(const Duration(days: 8)),
      nights: 2,
      guestsCount: 2,
      roomsCount: 1,
      selectedAddOns: [],
      roomTotal: sampleHotel.roomTypes.first.pricePerNight * 2,
      addOnsTotal: 0,
      taxesAndFees: 1200,
      grandTotal: (sampleHotel.roomTypes.first.pricePerNight * 2) + 1200,
      guestName: 'Gopi Ganesh',
      guestEmail: 'gopi.ganesh@plaza.club',
      guestPhone: '+91 98765 43210',
      specialRequests: 'High floor lake view room',
      qrCodeData: 'STY-ITC-44019-PASS',
      paymentMethod: 'Corporate Card',
      bookingTime: now.subtract(const Duration(days: 12)),
    );

    // 7. Sports Booking Seed (Cancelled)
    final sampleSport = SportsMockData.venues.first;
    final sampleSportsSlot = sampleSport.availableSlots.first;
    final sampleSportsBooking = SportsBooking(
      bookingId: 'PLZ-SPT-90218',
      venue: sampleSport,
      sport: sampleSport.supportedSports.first,
      date: now.subtract(const Duration(days: 1)),
      slot: sampleSportsSlot,
      durationMinutes: 60,
      playersCount: 6,
      addOns: [],
      isSquadBooking: true,
      squadName: 'Hyderabad Strikers',
      courtPrice: 1200,
      addOnsTotal: 250,
      convenienceFee: 50,
      grandTotal: 1500,
      perPersonCost: 250,
      bookerName: 'Gopi Ganesh',
      bookerPhone: '+91 98765 43210',
      qrCodeData: 'SPT-BOX-90218-CANCEL',
      paymentMethod: 'UPI',
      bookingTime: now.subtract(const Duration(days: 2)),
    );

    // Populate all 7 bookings into unified list
    _bookings.addAll([
      UnifiedBooking(
        id: sampleMovieBooking.bookingId,
        type: UnifiedBookingType.movie,
        title: sampleMovieBooking.movie.title,
        subtitle: '${sampleMovieBooking.theatre.name} • ${sampleMovieBooking.showtime.format.label}',
        location: 'Kondapur, Hyderabad',
        date: sampleMovieBooking.date,
        time: sampleMovieBooking.showtime.time,
        imageUrl: sampleMovieBooking.movie.posterUrl,
        status: BookingStatus.upcoming,
        totalAmount: sampleMovieBooking.grandTotal,
        confirmationCode: 'QR-MOV-84920-IMAX',
        seatOrSlotInfo: '${sampleMovieBooking.seatsFormatted} (${sampleMovieBooking.showtime.screenName})',
        movieBooking: sampleMovieBooking,
      ),
      UnifiedBooking(
        id: sampleDiningReservation.reservationId,
        type: UnifiedBookingType.dining,
        title: sampleDiningReservation.restaurant.name,
        subtitle: '${sampleDiningReservation.partySize} Guests • ${sampleDiningReservation.seatingPreference.label}',
        location: sampleDiningReservation.restaurant.location,
        date: sampleDiningReservation.date,
        time: sampleDiningReservation.timeSlot,
        imageUrl: sampleDiningReservation.restaurant.coverImageUrl,
        status: BookingStatus.upcoming,
        totalAmount: 0,
        confirmationCode: 'QR-DIN-38102-TABLE',
        seatOrSlotInfo: 'Table Reserved • ${sampleDiningReservation.seatingPreference.label}',
        diningReservation: sampleDiningReservation,
      ),
      UnifiedBooking(
        id: sampleEventBooking.bookingId,
        type: UnifiedBookingType.event,
        title: sampleEventBooking.event.title,
        subtitle: sampleEventBooking.ticketTier.name,
        location: sampleEventBooking.event.venue,
        date: sampleEventBooking.date,
        time: sampleEventBooking.event.time,
        imageUrl: sampleEventBooking.event.posterUrl,
        status: BookingStatus.upcoming,
        totalAmount: sampleEventBooking.grandTotal,
        confirmationCode: 'QR-EVT-77201-VIP',
        seatOrSlotInfo: 'VIP Lounge Gate 3',
        eventBooking: sampleEventBooking,
      ),
      UnifiedBooking(
        id: sampleActivityBooking.bookingId,
        type: UnifiedBookingType.activity,
        title: sampleActivityBooking.activity.title,
        subtitle: sampleActivityBooking.package.name,
        location: sampleActivityBooking.activity.location,
        date: sampleActivityBooking.date,
        time: sampleActivityBooking.timeSlot,
        imageUrl: sampleActivityBooking.activity.coverImageUrl,
        status: BookingStatus.active,
        totalAmount: sampleActivityBooking.grandTotal,
        confirmationCode: 'QR-ACT-19402-PITLANE',
        seatOrSlotInfo: 'Bay #04 • 3 Go-Karts Active',
        activityBooking: sampleActivityBooking,
      ),
      UnifiedBooking(
        id: sampleShoppingOrder.orderId,
        type: UnifiedBookingType.shopping,
        title: 'Rare Rabbit Express Pickup',
        subtitle: '1 item • Inorbit Mall Hitec City',
        location: 'Hitec City, Hyderabad',
        date: sampleShoppingOrder.orderTime,
        time: 'Express Pickup',
        imageUrl: sampleProduct.coverImageUrl,
        status: BookingStatus.completed,
        totalAmount: sampleShoppingOrder.grandTotal,
        confirmationCode: 'QR-ORD-83912-PICKUP',
        seatOrSlotInfo: 'Counter 2 • Delivered',
        shoppingOrder: sampleShoppingOrder,
      ),
      UnifiedBooking(
        id: sampleStayBooking.bookingId,
        type: UnifiedBookingType.stay,
        title: sampleStayBooking.hotel.name,
        subtitle: '${sampleStayBooking.roomType.name} (2 Nights)',
        location: sampleStayBooking.hotel.location,
        date: sampleStayBooking.checkInDate,
        time: 'Check-in: ${sampleStayBooking.hotel.checkInTime}',
        imageUrl: sampleStayBooking.hotel.coverImageUrl,
        status: BookingStatus.completed,
        totalAmount: sampleStayBooking.grandTotal,
        confirmationCode: 'QR-STY-44019-SUITE',
        seatOrSlotInfo: 'Club Suite #1204',
        hotelBooking: sampleStayBooking,
      ),
      UnifiedBooking(
        id: sampleSportsBooking.bookingId,
        type: UnifiedBookingType.sports,
        title: sampleSportsBooking.venue.name,
        subtitle: '${sampleSportsBooking.sport.label} • 60 mins',
        location: sampleSportsBooking.venue.location,
        date: sampleSportsBooking.date,
        time: sampleSportsBooking.slot.time,
        imageUrl: sampleSportsBooking.venue.coverImageUrl,
        status: BookingStatus.cancelled,
        totalAmount: sampleSportsBooking.grandTotal,
        confirmationCode: 'QR-SPT-90218-CANCEL',
        seatOrSlotInfo: 'Pitch #1 • Cancelled & Refunded',
        sportsBooking: sampleSportsBooking,
      ),
    ]);

    // Seed Saved Plans
    _savedPlans.addAll([
      PlazaPlan(
        id: 'pln_sample_1',
        title: 'Jubilee Hills Weekend Escape',
        subtitle: 'Adrenaline, Pan-Asian flavors & IMAX cinema',
        mood: PlanMood.friends,
        peopleCount: 3,
        locationArea: 'Jubilee Hills & Kondapur',
        date: now.add(const Duration(days: 2)),
        isSaved: true,
        items: const [
          PlanItem(
            id: 'item_1',
            vertical: UnifiedBookingType.activity,
            title: 'High-Speed Go-Karting Championship',
            venue: 'Runway 9 International Circuit',
            area: 'Outer Ring Road, Kompally',
            time: '3:30 PM',
            duration: '90 mins',
            costPerPerson: 850,
            imageUrl: 'https://images.unsplash.com/photo-1568605117036-5fe5e7bab0b7?q=80&w=800&auto=format&fit=crop',
            note: 'Safety helmets & timing transponder included',
            slot: PlanTimeSlot.afternoon,
          ),
          PlanItem(
            id: 'item_2',
            vertical: UnifiedBookingType.dining,
            title: 'Modern Indian Dinner & Molecular Cocktails',
            venue: 'Farzi Café & Cocktail Lounge',
            area: 'Road No. 36, Jubilee Hills',
            time: '7:00 PM',
            duration: '100 mins',
            costPerPerson: 1200,
            imageUrl: 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?q=80&w=800&auto=format&fit=crop',
            note: 'Rooftop table reserved with 25% PLAZA Club discount',
            slot: PlanTimeSlot.evening,
          ),
          PlanItem(
            id: 'item_3',
            vertical: UnifiedBookingType.movie,
            title: 'Dune: Part Two (IMAX with Laser)',
            venue: 'AMB Cinemas, Screen 1',
            area: 'Sarath City Capital Mall, Kondapur',
            time: '9:45 PM',
            duration: '166 mins',
            costPerPerson: 450,
            imageUrl: 'https://images.unsplash.com/photo-1534447677768-be436bb09401?q=80&w=800&auto=format&fit=crop',
            note: 'Platinum Recliner seats K12-K14 confirmed',
            slot: PlanTimeSlot.night,
          ),
        ],
      ),
      PlazaPlan(
        id: 'pln_sample_2',
        title: 'Heritage & Royalty Day Out',
        subtitle: 'Old City Irani chai, crafts & palace high-tea',
        mood: PlanMood.luxury,
        peopleCount: 2,
        locationArea: 'Old City & Falaknuma',
        date: now.add(const Duration(days: 5)),
        isSaved: true,
        items: const [
          PlanItem(
            id: 'item_4',
            vertical: UnifiedBookingType.activity,
            title: 'Historic Charminar & Perfume Walk',
            venue: 'Laad Bazaar Heritage Trail',
            area: 'Old City, Hyderabad',
            time: '10:00 AM',
            duration: '120 mins',
            costPerPerson: 400,
            imageUrl: 'https://images.unsplash.com/photo-1589308078059-be1415eab4c3?q=80&w=800&auto=format&fit=crop',
            note: 'Guided private walk with artisanal ittar sampling',
            slot: PlanTimeSlot.morning,
          ),
          PlanItem(
            id: 'item_5',
            vertical: UnifiedBookingType.dining,
            title: 'Royal Nizami Feast & High Tea',
            venue: 'Adaa at Taj Falaknuma Palace',
            area: 'Engine Bowli, Falaknuma',
            time: '4:30 PM',
            duration: '150 mins',
            costPerPerson: 3500,
            imageUrl: 'https://images.unsplash.com/photo-1544025162-d76694265947?q=80&w=800&auto=format&fit=crop',
            note: 'Palace carriage arrival & 5-course curated tasting',
            slot: PlanTimeSlot.afternoon,
          ),
        ],
      ),
    ]);

    // Seed Recently Viewed
    _recentlyViewed.addAll([
      RecentlyViewedItem(
        id: 'mov_1',
        title: 'Dune: Part Two',
        category: 'Movie • IMAX 3D',
        imageUrl: 'https://images.unsplash.com/photo-1534447677768-be436bb09401?q=80&w=800&auto=format&fit=crop',
        rating: '4.9 ★',
        location: 'AMB Cinemas, Kondapur',
        priceInfo: 'From ₹350',
        viewedAt: now.subtract(const Duration(minutes: 15)),
      ),
      RecentlyViewedItem(
        id: 'rest_1',
        title: 'Farzi Café & Lounge',
        category: 'Dining • Modern Indian',
        imageUrl: 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?q=80&w=800&auto=format&fit=crop',
        rating: '4.8 ★',
        location: 'Jubilee Hills',
        priceInfo: '₹1,800 for two',
        viewedAt: now.subtract(const Duration(hours: 1)),
      ),
      RecentlyViewedItem(
        id: 'hotel_1',
        title: 'ITC Kohenur Luxury Collection',
        category: 'Stays • 5-Star Hotel',
        imageUrl: 'https://images.unsplash.com/photo-1566073771259-6a8506099945?q=80&w=800&auto=format&fit=crop',
        rating: '4.9 ★',
        location: 'HITEC City, Durgam Cheruvu',
        priceInfo: '₹14,500 / night',
        viewedAt: now.subtract(const Duration(hours: 4)),
      ),
      RecentlyViewedItem(
        id: 'act_1',
        title: 'Runway 9 Go-Karting Track',
        category: 'Activities • Karting & Arcade',
        imageUrl: 'https://images.unsplash.com/photo-1568605117036-5fe5e7bab0b7?q=80&w=800&auto=format&fit=crop',
        rating: '4.8 ★',
        location: 'Outer Ring Road, Kompally',
        priceInfo: '₹450 / 8 laps',
        viewedAt: now.subtract(const Duration(hours: 7)),
      ),
      RecentlyViewedItem(
        id: 'sp_1',
        title: 'The Box Cricket Arena',
        category: 'Sports • Floodlit Turf',
        imageUrl: 'https://images.unsplash.com/photo-1531415074868-036b107e775a?q=80&w=800&auto=format&fit=crop',
        rating: '4.8 ★',
        location: 'Financial District, Nanakramguda',
        priceInfo: '₹1,200 / hr',
        viewedAt: now.subtract(const Duration(days: 1)),
      ),
    ]);

    // Seed Rewards Vouchers
    _vouchers.addAll([
      RewardVoucher(
        id: 'vch_1',
        title: '₹200 Off Movies',
        description: 'Valid at AMB, PVR & Prasads IMAX',
        pointsCost: 1500,
        discountAmount: 200,
        minSpend: 600,
        code: 'PLZ-MOV200',
        category: RewardCategory.movie,
        expiryDate: now.add(const Duration(days: 30)),
      ),
      RewardVoucher(
        id: 'vch_2',
        title: '₹500 Off Fine Dining',
        description: 'Flat ₹500 off at Farzi, Olive Bistro & Jewel of Nizam',
        pointsCost: 3500,
        discountAmount: 500,
        minSpend: 2000,
        code: 'PLZ-DINE500',
        category: RewardCategory.dining,
        expiryDate: now.add(const Duration(days: 45)),
      ),
      RewardVoucher(
        id: 'vch_3',
        title: 'Free Gourmet Popcorn Combo',
        description: 'Caramel Tub + 2 Craft Cold Coffees',
        pointsCost: 900,
        discountAmount: 420,
        minSpend: 0,
        code: 'PLZ-SNACKFREE',
        category: RewardCategory.movie,
        expiryDate: now.add(const Duration(days: 14)),
      ),
      RewardVoucher(
        id: 'vch_4',
        title: '₹1,000 Off Luxury Staycation',
        description: 'Valid at ITC Kohenur, Park Hyatt & Taj Falaknuma',
        pointsCost: 5000,
        discountAmount: 1000,
        minSpend: 8000,
        code: 'PLZ-STAY1000',
        category: RewardCategory.stay,
        expiryDate: now.add(const Duration(days: 60)),
      ),
      RewardVoucher(
        id: 'vch_5',
        title: 'Free Pit-Pass Lap Upgrade',
        description: 'Extra 4 laps with pro timing at Runway 9',
        pointsCost: 750,
        discountAmount: 300,
        minSpend: 500,
        code: 'PLZ-PITPASS',
        category: RewardCategory.activity,
        expiryDate: now.add(const Duration(days: 20)),
      ),
    ]);

    // Seed Rewards Transactions
    _rewardTransactions.addAll([
      RewardTransaction(
        id: 'tx_1',
        title: 'Dune: Part Two IMAX Booking',
        description: 'Points earned at AMB Cinemas',
        pointsChange: 150,
        timestamp: now.subtract(const Duration(hours: 3)),
        isCredit: true,
      ),
      RewardTransaction(
        id: 'tx_2',
        title: 'Farzi Café Jubilee Hills',
        description: 'Points earned on dinner bill',
        pointsChange: 280,
        timestamp: now.subtract(const Duration(days: 2)),
        isCredit: true,
      ),
      RewardTransaction(
        id: 'tx_3',
        title: 'Go-Karting Squad Booking',
        description: 'Bonus squad multiplier earned',
        pointsChange: 180,
        timestamp: now.subtract(const Duration(days: 5)),
        isCredit: true,
      ),
      RewardTransaction(
        id: 'tx_4',
        title: 'Welcome to PLAZA Black Tier',
        description: 'Sign-up tier bonus awarded',
        pointsChange: 1870,
        timestamp: now.subtract(const Duration(days: 15)),
        isCredit: true,
      ),
    ]);

    // Seed Notifications
    _notifications.addAll([
      const PlazaNotification(
        id: 'notif_1',
        title: 'Show Starts in 3 Hours! 🍿',
        message: 'Your Dune: Part Two IMAX booking at AMB Cinemas starts at 7:30 PM. Click to view entry pass.',
        timeAgo: '15m ago',
        category: PlazaNotificationCategory.bookings,
        isRead: false,
      ),
      const PlazaNotification(
        id: 'notif_2',
        title: 'Exclusive 25% Off Dining 🏷️',
        message: 'Enjoy 25% off your bill at Farzi Café Jubilee Hills this entire weekend with PLAZA Black.',
        timeAgo: '2h ago',
        category: PlazaNotificationCategory.deals,
        isRead: false,
      ),
      const PlazaNotification(
        id: 'notif_3',
        title: 'Your Weekend Plan is Ready ✨',
        message: 'PLAZA Concierge has refreshed your Jubilee Hills Weekend Escape itinerary with live availability.',
        timeAgo: '5h ago',
        category: PlazaNotificationCategory.plans,
        isRead: false,
      ),
      const PlazaNotification(
        id: 'notif_4',
        title: '+150 PLAZA Points Credited 🎁',
        message: 'You earned 150 points for your cinema booking. Your current balance is 2,480 points.',
        timeAgo: '1d ago',
        category: PlazaNotificationCategory.rewards,
        isRead: true,
      ),
      const PlazaNotification(
        id: 'notif_5',
        title: 'Box Cricket Arena Slot Alert ⚡',
        message: 'Prime Friday 8 PM floodlit slot at Financial District just opened up. Book now before it sells out.',
        timeAgo: '2d ago',
        category: PlazaNotificationCategory.alerts,
        isRead: true,
      ),
    ]);
  }
}
