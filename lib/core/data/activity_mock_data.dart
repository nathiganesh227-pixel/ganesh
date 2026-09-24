import '../models/activity.dart';

class ActivityMockData {
  ActivityMockData._();

  static final List<PlazaActivity> activities = [
    const PlazaActivity(
      id: 'act_1',
      title: 'Smaaash Cosmic Bowling & VR Zone',
      venueName: 'Smaaash Entertainment Arena',
      location: 'Inorbit Mall, Level 5, Hitec City',
      distance: '3.1 km',
      category: ActivityCategoryType.bowling,
      coverImageUrl:
          'https://images.unsplash.com/photo-1538370965046-79c0d6907d47?q=80&w=800&auto=format&fit=crop',
      gallery: [
        'https://images.unsplash.com/photo-1538370965046-79c0d6907d47?q=80&w=800&auto=format&fit=crop',
      ],
      rating: 4.8,
      reviewCount: 3200,
      duration: '45 mins / game',
      startingPrice: 450,
      liveAvailabilityLabel: '2 lanes available at 7:30 PM',
      about:
          'State of the art UV twilight bowling alleys with computerized scoring, pulsing club music, arcade games, and dynamic pin lighting.',
      whatIsIncluded: [
        'Bowling shoes & shoe covers',
        'Dedicated lane for up to 6 players',
        '1 Game (10 frames per player)',
        'Full access to lounge and bar',
      ],
      requirements: [
        'Socks mandatory (available on site for ₹50)',
        'Arrive 10 minutes before booked slot',
      ],
      packages: [
        ActivityPackage(
          id: 'pkg_std',
          name: 'Standard Game',
          description: '1 full bowling game with shoes included',
          pricePerPerson: 450,
          duration: '45 mins',
          includedFeatures: ['1 Bowling Game', 'Shoe Rental', 'Lounge Access'],
        ),
        ActivityPackage(
          id: 'pkg_unlimited',
          name: 'Blockbuster Combo (Game + Food)',
          description: '1 Bowling game + Large Nachos + Pitcher of soft beverage',
          pricePerPerson: 750,
          duration: '1 Hour',
          includedFeatures: ['1 Bowling Game', 'Shoe Rental', 'Nachos with Cheese Dip', 'Beverage'],
        ),
        ActivityPackage(
          id: 'pkg_party',
          name: 'Squad Party Lane (Up to 6 people)',
          description: 'Unlimited 1-hour lane booking for up to 6 players with snacks platter',
          pricePerPerson: 2200,
          duration: '60 mins',
          includedFeatures: ['Exclusive Lane', 'Up to 6 Players', 'Party Snacks Platter', 'Arcade Credits'],
        ),
      ],
      availableSlots: [
        ActivityTimeSlot(time: '04:00 PM', availableSlots: 4),
        ActivityTimeSlot(time: '05:30 PM', availableSlots: 2, isFillingFast: true),
        ActivityTimeSlot(time: '07:30 PM', availableSlots: 2, isFillingFast: true),
        ActivityTimeSlot(time: '09:00 PM', availableSlots: 3),
        ActivityTimeSlot(time: '10:30 PM', availableSlots: 5),
      ],
      isTrending: true,
      isGroupPick: true,
      isAvailableNow: true,
    ),
    const PlazaActivity(
      id: 'act_2',
      title: 'Speedway Pro Go-Karting Track',
      venueName: 'Speedway Motor Sports Arena',
      location: 'Airport Approach Road, Shamshabad',
      distance: '12 km',
      category: ActivityCategoryType.goKarting,
      coverImageUrl:
          'https://images.unsplash.com/photo-1568605117036-5fe5e7bab0b7?q=80&w=800&auto=format&fit=crop',
      gallery: [
        'https://images.unsplash.com/photo-1568605117036-5fe5e7bab0b7?q=80&w=800&auto=format&fit=crop',
      ],
      rating: 4.9,
      reviewCount: 4100,
      duration: '10 mins / session',
      startingPrice: 850,
      liveAvailabilityLabel: 'Karts ready for immediate session',
      about:
          'Hyderabad’s longest 900-meter asphalt professional go-karting circuit featuring Sodi RT8 270cc 4-stroke racing karts, live F1 timing telemetry, and night track floodlights.',
      whatIsIncluded: [
        'Sodi RT8 270cc racing kart',
        'DOT-certified full face helmet & neck brace',
        'F1 RFID timing printout sheet',
        'Track briefing by certified safety marshals',
      ],
      requirements: [
        'Minimum height 4 feet 8 inches',
        'Closed-toe shoes mandatory (no sandals or heels)',
      ],
      packages: [
        ActivityPackage(
          id: 'pkg_kart_single',
          name: '7-Lap Qualifier Session',
          description: '7 timed high-speed laps on the 900m pro track',
          pricePerPerson: 850,
          duration: '10 mins',
          includedFeatures: ['7 Racing Laps', 'Safety Helmet', 'Live Telemetry Sheet'],
        ),
        ActivityPackage(
          id: 'pkg_kart_double',
          name: 'Twin-Engine 14-Lap Grand Prix',
          description: '14 laps split across 2 heats with podium ceremony',
          pricePerPerson: 1500,
          duration: '25 mins',
          includedFeatures: ['14 Laps (2 Heats)', 'Podium Ceremony', 'Energy Drink'],
        ),
      ],
      availableSlots: [
        ActivityTimeSlot(time: '04:30 PM', availableSlots: 6),
        ActivityTimeSlot(time: '06:00 PM', availableSlots: 3, isFillingFast: true),
        ActivityTimeSlot(time: '07:30 PM', availableSlots: 1, isFillingFast: true),
        ActivityTimeSlot(time: '09:00 PM', availableSlots: 4),
      ],
      isTrending: true,
      isGroupPick: true,
      isAvailableNow: true,
    ),
    const PlazaActivity(
      id: 'act_3',
      title: 'Gachibowli Box Cricket & Football Turf',
      venueName: 'The Arena Sports Hub',
      location: 'Behind Bio-Diversity Park, Gachibowli',
      distance: '2.8 km',
      category: ActivityCategoryType.cricket,
      coverImageUrl:
          'https://images.unsplash.com/photo-1529900245534-47fbf8204bca?q=80&w=800&auto=format&fit=crop',
      gallery: [
        'https://images.unsplash.com/photo-1529900245534-47fbf8204bca?q=80&w=800&auto=format&fit=crop',
      ],
      rating: 4.7,
      reviewCount: 1800,
      duration: '60 mins / slot',
      startingPrice: 1200,
      liveAvailabilityLabel: 'Floodlights On • 1 court available at 7:00 PM',
      about:
          'High density FIFA-approved astro-turf multi-sport box equipped with powerful stadium-grade LED floodlights, nets, cricket bats, balls, and bibs.',
      whatIsIncluded: [
        'Exclusive full box turf for 1 hour',
        'Tennis balls & high-grade English willow bats',
        'Stumps, bibs, and footballs',
        'Covered dugout with mist coolers',
      ],
      requirements: [
        'Sports shoes / non-metal studs required',
        'Max 14 players allowed on turf at once',
      ],
      packages: [
        ActivityPackage(
          id: 'pkg_turf_1hr',
          name: '1 Hour Box Turf Rental',
          description: 'Full court booking for up to 14 players with all cricket gear',
          pricePerPerson: 1200,
          duration: '60 mins',
          includedFeatures: ['Full Turf 1 Hour', 'Bats & Balls', 'Dugout Access'],
        ),
        ActivityPackage(
          id: 'pkg_turf_2hr',
          name: '2 Hours Match Session',
          description: '2 continuous hours ideal for full 10-over matches with tournament scoreboard',
          pricePerPerson: 2200,
          duration: '120 mins',
          includedFeatures: ['Full Turf 2 Hours', 'Scoreboard Access', 'Cold Drinking Water'],
        ),
      ],
      availableSlots: [
        ActivityTimeSlot(time: '06:00 PM', availableSlots: 1, isFillingFast: true),
        ActivityTimeSlot(time: '07:00 PM', availableSlots: 1, isFillingFast: true),
        ActivityTimeSlot(time: '08:00 PM', availableSlots: 1, isFillingFast: true),
        ActivityTimeSlot(time: '09:00 PM', availableSlots: 2),
        ActivityTimeSlot(time: '10:00 PM', availableSlots: 2),
      ],
      isTrending: false,
      isGroupPick: true,
      isAvailableNow: true,
    ),
    const PlazaActivity(
      id: 'act_4',
      title: 'Mystery Rooms – Live Escape Experience',
      venueName: 'Mystery Rooms Jubilee Hills',
      location: 'Road No. 36, Near Peddamma Temple',
      distance: '2.5 km',
      category: ActivityCategoryType.escapeRooms,
      coverImageUrl:
          'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?q=80&w=800&auto=format&fit=crop',
      gallery: [
        'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?q=80&w=800&auto=format&fit=crop',
      ],
      rating: 4.9,
      reviewCount: 2200,
      duration: '60 mins',
      startingPrice: 800,
      liveAvailabilityLabel: '3 mission rooms ready to book',
      about:
          'Challenging immersive real-life mystery adventure where you and your team are locked in a themed room and have 60 minutes to crack codes, find hidden clues, and escape.',
      whatIsIncluded: [
        '60-Minute themed mystery mission',
        'Clue-master walkie-talkie support',
        'Post-mission team photo with props',
      ],
      requirements: [
        'Team size: 2 to 8 players',
        'No phones or recording devices inside the room',
      ],
      packages: [
        ActivityPackage(
          id: 'pkg_mr_std',
          name: 'The Lockout (Prison Break)',
          description: 'Escape from a high security prison cell within 60 mins',
          pricePerPerson: 800,
          duration: '60 mins',
          includedFeatures: ['Prison Break Mission', 'Clue Support', 'Team Photo'],
        ),
        ActivityPackage(
          id: 'pkg_mr_horror',
          name: 'The Cabin in the Woods (Horror Thriller)',
          description: 'Dark horror thriller mission with live scare actors',
          pricePerPerson: 950,
          duration: '60 mins',
          includedFeatures: ['Live Actor Scare Elements', 'Heart-racing Puzzles'],
        ),
      ],
      availableSlots: [
        ActivityTimeSlot(time: '03:00 PM', availableSlots: 3),
        ActivityTimeSlot(time: '05:00 PM', availableSlots: 1, isFillingFast: true),
        ActivityTimeSlot(time: '07:00 PM', availableSlots: 2),
        ActivityTimeSlot(time: '08:30 PM', availableSlots: 2),
      ],
      isTrending: true,
      isGroupPick: true,
      isAvailableNow: false,
    ),
  ];
}
