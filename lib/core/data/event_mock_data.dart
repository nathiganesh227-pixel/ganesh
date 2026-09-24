import '../models/event.dart';

class EventMockData {
  EventMockData._();

  static final List<PlazaEvent> events = [
    PlazaEvent(
      id: 'event_1',
      title: 'Sunburn Arena ft. Alan Walker',
      tagline: 'WalkerWorld India Tour 2024 • Hyderabad Edition',
      description:
          'Global electronic music phenomenon Alan Walker is taking over Hyderabad with a massive audio-visual production, immersive LED stages, and chart-topping anthems like Faded, Alone, and The Spectre.',
      category: EventCategoryType.concerts,
      posterUrl:
          'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?q=80&w=800&auto=format&fit=crop',
      bannerUrl:
          'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?q=80&w=1200&auto=format&fit=crop',
      eventDate: DateTime.now().add(const Duration(days: 4)),
      time: '05:00 PM – 10:30 PM',
      venue: 'Hitex Exhibition Center',
      location: 'Trade Fair Grounds, Hitec City',
      distance: '5.8 km',
      rating: 4.9,
      interestedCount: 14200,
      ageRestriction: '16+',
      language: 'English',
      duration: '5h 30m',
      isHappeningToday: false,
      isThisWeekend: true,
      isTrending: true,
      artists: const [
        Performer(
          name: 'Alan Walker',
          role: 'Headliner DJ / Producer',
          imageUrl: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?q=80&w=300&auto=format&fit=crop',
        ),
        Performer(
          name: 'Julia Berg',
          role: 'Supporting Live Vocalist',
          imageUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=300&auto=format&fit=crop',
        ),
      ],
      ticketTiers: const [
        EventTicketTier(
          id: 'tier_ga',
          name: 'General Access (GA)',
          description: 'Access to main arena ground standing area and F&B village',
          price: 1499,
          remainingCount: 120,
          perks: ['Main arena entry', 'Food village access'],
        ),
        EventTicketTier(
          id: 'tier_vip',
          name: 'VIP Front Stage',
          description: 'Dedicated express entry gate, elevated front-stage deck, and separate bar access',
          price: 3299,
          remainingCount: 45,
          perks: ['Express Gate Entry', 'Elevated Viewing Deck', 'Dedicated Bar', 'Exclusive Restrooms'],
        ),
        EventTicketTier(
          id: 'tier_fanpit',
          name: 'Fan Pit (Right in front of DJ)',
          description: 'Closest proximity to the stage with commemorative lanyard and poster',
          price: 5499,
          remainingCount: 12,
          perks: ['Right in front of stage', 'Official Merchandise Pack', 'Free Welcome Drink'],
        ),
      ],
      highlights: [
        'Massive 360-degree holographic laser setup',
        'Over 15,000 music enthusiasts',
        'Gourmet food truck festival inside the venue',
      ],
      gallery: const [
        'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?q=80&w=800&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?q=80&w=800&auto=format&fit=crop',
      ],
    ),
    PlazaEvent(
      id: 'event_2',
      title: 'Zakir Khan Live: Tathastu & Beyond',
      tagline: 'The Rondu Sakht Launda returns with brand new unreleased jokes',
      description:
          'Zakir Khan is back on stage with his soul-stirring blend of humor, nostalgia, emotion, and relatable storytelling about friendship, middle-class quirks, and adulthood.',
      category: EventCategoryType.comedy,
      posterUrl:
          'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?q=80&w=800&auto=format&fit=crop',
      bannerUrl:
          'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?q=80&w=1200&auto=format&fit=crop',
      eventDate: DateTime.now().add(const Duration(days: 2)),
      time: '07:30 PM – 09:30 PM',
      venue: 'Shilpakala Vedika Auditorium',
      location: 'Hitec City Main Road',
      distance: '4.1 km',
      rating: 4.9,
      interestedCount: 8900,
      ageRestriction: '16+',
      language: 'Hindi',
      duration: '2 Hours',
      isHappeningToday: false,
      isThisWeekend: true,
      isTrending: true,
      artists: const [
        Performer(
          name: 'Zakir Khan',
          role: 'Stand-up Comedian',
          imageUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?q=80&w=300&auto=format&fit=crop',
        ),
      ],
      ticketTiers: const [
        EventTicketTier(
          id: 'zk_silver',
          name: 'Balcony Silver',
          description: 'Upper tier reserved seating with clear stage view',
          price: 999,
          remainingCount: 30,
          perks: ['Reserved seat'],
        ),
        EventTicketTier(
          id: 'zk_gold',
          name: 'Stalls Gold',
          description: 'Ground floor middle row seating',
          price: 1999,
          remainingCount: 18,
          perks: ['Ground floor view', 'Fast track auditorium entry'],
        ),
        EventTicketTier(
          id: 'zk_platinum',
          name: 'Platinum Front Rows',
          description: 'First 5 rows right in front of the stage',
          price: 3499,
          remainingCount: 4,
          perks: ['Front row prime seats', 'VIP lounge access prior to show'],
        ),
      ],
      highlights: [
        '100% Brand new 90-minute stand-up special',
        'State-of-the-art auditorium acoustics',
      ],
      gallery: const [
        'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?q=80&w=800&auto=format&fit=crop',
      ],
    ),
    PlazaEvent(
      id: 'event_3',
      title: 'Hyderabad International Jazz & Blues Fest',
      tagline: 'Open-air soul, saxophones, and craft brews under the stars',
      description:
          'Experience three legendary jazz and blues ensembles from France, USA, and India collaborating for an unforgettable musical night with artisanal wines and gourmet cheeses.',
      category: EventCategoryType.concerts,
      posterUrl:
          'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?q=80&w=800&auto=format&fit=crop',
      bannerUrl:
          'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?q=80&w=1200&auto=format&fit=crop',
      eventDate: DateTime.now(),
      time: '06:30 PM – 11:00 PM',
      venue: 'Qutb Shahi Tombs Amphitheatre',
      location: 'Ibrahim Bagh, Hyderabad',
      distance: '8.4 km',
      rating: 4.8,
      interestedCount: 3400,
      ageRestriction: 'All Ages',
      language: 'Instrumental / English',
      duration: '4h 30m',
      isHappeningToday: true,
      isThisWeekend: false,
      isTrending: false,
      artists: const [
        Performer(
          name: 'The French Quintet',
          role: 'Jazz Ensemble',
          imageUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?q=80&w=300&auto=format&fit=crop',
        ),
      ],
      ticketTiers: const [
        EventTicketTier(
          id: 'jazz_single',
          name: 'Lawn Pass',
          description: 'Open lawn amphitheatre seating with picnic mat access',
          price: 750,
          remainingCount: 40,
        ),
        EventTicketTier(
          id: 'jazz_couples',
          name: 'Couples Wine & Dine Pass',
          description: 'Entry for 2 + 2 glasses of imported wine + Cheese platter',
          price: 2400,
          remainingCount: 14,
        ),
      ],
      highlights: [
        'Heritage monument backdrop with mood lighting',
        'Craft beers & gourmet charcuterie boards',
      ],
      gallery: const [
        'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?q=80&w=800&auto=format&fit=crop',
      ],
    ),
    PlazaEvent(
      id: 'event_4',
      title: 'Comic Con India – Hyderabad 2024',
      tagline: 'The ultimate pop culture, anime & gaming festival',
      description:
          'Celebrity comic creators, international cosplayers, gaming tournaments, exclusive merchandise, and special panels from Marvel and DC artists.',
      category: EventCategoryType.exhibitions,
      posterUrl:
          'https://images.unsplash.com/photo-1607604276583-eef5d076aa5f?q=80&w=800&auto=format&fit=crop',
      bannerUrl:
          'https://images.unsplash.com/photo-1607604276583-eef5d076aa5f?q=80&w=1200&auto=format&fit=crop',
      eventDate: DateTime.now().add(const Duration(days: 6)),
      time: '11:00 AM – 08:00 PM',
      venue: 'Hitex Exhibition Center (Hall 1 & 2)',
      location: 'Hitec City',
      distance: '5.8 km',
      rating: 4.8,
      interestedCount: 22000,
      ageRestriction: 'All Ages',
      language: 'English',
      duration: 'Full Day',
      isHappeningToday: false,
      isThisWeekend: false,
      isTrending: true,
      artists: const [
        Performer(
          name: 'Gaurav Basu',
          role: 'Featured Artist',
          imageUrl: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?q=80&w=300&auto=format&fit=crop',
        ),
      ],
      ticketTiers: const [
        EventTicketTier(
          id: 'cc_single',
          name: '1-Day General Entry',
          description: 'Single day access to all exhibition zones and main stage panels',
          price: 899,
          remainingCount: 200,
        ),
        EventTicketTier(
          id: 'cc_superfan',
          name: 'SuperFan VIP Weekend Pass',
          description: '2-Day entry with exclusive Comic Con cape, t-shirt & fast track celebrity meet',
          price: 2999,
          remainingCount: 25,
        ),
      ],
      highlights: [
        'Cosplay grand championship with ₹5 Lakh prize pool',
        'Official merchandise booths from Funko, Manga & Marvel',
      ],
      gallery: const [
        'https://images.unsplash.com/photo-1607604276583-eef5d076aa5f?q=80&w=800&auto=format&fit=crop',
      ],
    ),
  ];
}
