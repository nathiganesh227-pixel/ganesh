import '../models/dining.dart';

class DiningMockData {
  DiningMockData._();

  static final List<Restaurant> restaurants = [
    const Restaurant(
      id: 'rest_1',
      name: 'Farzi Café & Cocktail Lounge',
      tagline: 'Modern Indian culinary illusion & craft mixology',
      about:
          'Farzi Café brings a gourmet blend of authentic Indian flavors infused with contemporary molecular gastronomy techniques, sophisticated rooftop ambiance, and signature mixology cocktails in the heart of Jubilee Hills.',
      coverImageUrl:
          'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?q=80&w=800&auto=format&fit=crop',
      galleryImages: [
        'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?q=80&w=800&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?q=80&w=800&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1544025162-d76694265947?q=80&w=800&auto=format&fit=crop',
      ],
      rating: 4.8,
      reviewCount: 1850,
      cuisines: [CuisineType.northIndian, CuisineType.telugu],
      priceForTwo: 1800,
      location: 'Road No. 36, Jubilee Hills',
      distance: '2.1 km',
      openingHours: '12:00 PM – 11:30 PM',
      isPureVeg: false,
      hasOutdoor: true,
      isOpenNow: true,
      offerBadge: 'FLAT 25% OFF with PLAZA CLUB',
      amenities: ['Rooftop Seating', 'Live DJ & Music', 'Valet Parking', 'Cocktail Bar', 'Full AC'],
      popularDishes: [
        DishItem(
          name: 'Dal Chawal Arancini',
          description: 'Crispy lentil rice sphere with mint foam & papad roll',
          price: 420,
          isVeg: true,
          isChefSpecial: true,
          imageUrl: 'https://images.unsplash.com/photo-1546833999-b9f581a1996d?q=80&w=400&auto=format&fit=crop',
        ),
        DishItem(
          name: 'Guntur Chilli Lamb Chops',
          description: 'Tender spiced lamb braised with fiery Andhra Guntur chilies',
          price: 680,
          isVeg: false,
          isChefSpecial: true,
          imageUrl: 'https://images.unsplash.com/photo-1544025162-d76694265947?q=80&w=400&auto=format&fit=crop',
        ),
        DishItem(
          name: 'Smoked Butter Chicken Bao',
          description: 'Steamed lotus bao buns stuffed with slow-cooked tandoori chicken',
          price: 540,
          isVeg: false,
          imageUrl: 'https://images.unsplash.com/photo-1563245372-f21724e3856d?q=80&w=400&auto=format&fit=crop',
        ),
      ],
      reviews: [
        DiningReview(
          userName: 'Aditi Rao',
          rating: 5.0,
          comment: 'Outstanding food presentation and lovely rooftop breeze. The Arancini is unforgettable.',
          date: '2 days ago',
        ),
        DiningReview(
          userName: 'Vikram Reddy',
          rating: 4.5,
          comment: 'Great cocktail menu and attentive service. Recommended for dates and weekend dinners.',
          date: '1 week ago',
        ),
      ],
      availableSlots: [
        DiningTimeSlot(time: '01:00 PM', status: SlotAvailabilityStatus.available, tablesLeft: 6),
        DiningTimeSlot(time: '07:00 PM', status: SlotAvailabilityStatus.fillingFast, tablesLeft: 3),
        DiningTimeSlot(time: '08:30 PM', status: SlotAvailabilityStatus.fewTablesLeft, tablesLeft: 2),
        DiningTimeSlot(time: '09:45 PM', status: SlotAvailabilityStatus.available, tablesLeft: 5),
      ],
      isTrending: true,
      isFineDining: false,
    ),
    const Restaurant(
      id: 'rest_2',
      name: 'Olive Bistro & Secret Garden',
      tagline: 'Mediterranean lakefront dining overlooking Durgam Cheruvu',
      about:
          'Set against the picturesque Durgam Cheruvu lake, Olive Bistro is a white-walled rustic Mediterranean haven featuring handcrafted woodfire sourdough pizzas, fresh pastas, and sangrias in an open-air cobblestone courtyard.',
      coverImageUrl:
          'https://images.unsplash.com/photo-1550966871-3ed3cdb5ed0c?q=80&w=800&auto=format&fit=crop',
      galleryImages: [
        'https://images.unsplash.com/photo-1550966871-3ed3cdb5ed0c?q=80&w=800&auto=format&fit=crop',
        'https://images.unsplash.com/photo-1513104890138-7c749659a591?q=80&w=800&auto=format&fit=crop',
      ],
      rating: 4.9,
      reviewCount: 2420,
      cuisines: [CuisineType.italian, CuisineType.cafe],
      priceForTwo: 2400,
      location: 'Road 46, Jubilee Hills Lakefront',
      distance: '3.2 km',
      openingHours: '12:30 PM – 11:00 PM',
      isPureVeg: false,
      hasOutdoor: true,
      isOpenNow: true,
      offerBadge: 'Complimentary Dessert on ₹2,000+',
      amenities: ['Lake View', 'Candlelight Seating', 'Pet Friendly', 'Wine Cellar', 'Valet'],
      popularDishes: [
        DishItem(
          name: 'Truffle Funghi Woodfire Pizza',
          description: 'Wild forest mushrooms, buffalo mozzarella, black truffle oil',
          price: 795,
          isVeg: true,
          isChefSpecial: true,
          imageUrl: 'https://images.unsplash.com/photo-1513104890138-7c749659a591?q=80&w=400&auto=format&fit=crop',
        ),
        DishItem(
          name: 'Handmade Lobster Ravioli',
          description: 'Saffron bisque sauce with fresh dill and shaved parmesan',
          price: 920,
          isVeg: false,
          isChefSpecial: true,
          imageUrl: 'https://images.unsplash.com/photo-1551183053-bf91a1d81141?q=80&w=400&auto=format&fit=crop',
        ),
      ],
      reviews: [
        DiningReview(
          userName: 'Kavya Sharma',
          rating: 5.0,
          comment: 'Magical sunset view by the lake! The pizza crust was authentic sourdough perfection.',
          date: 'Yesterday',
        ),
      ],
      availableSlots: [
        DiningTimeSlot(time: '01:30 PM', status: SlotAvailabilityStatus.available, tablesLeft: 4),
        DiningTimeSlot(time: '06:30 PM', status: SlotAvailabilityStatus.fewTablesLeft, tablesLeft: 1),
        DiningTimeSlot(time: '08:00 PM', status: SlotAvailabilityStatus.fewTablesLeft, tablesLeft: 2),
        DiningTimeSlot(time: '09:30 PM', status: SlotAvailabilityStatus.available, tablesLeft: 4),
      ],
      isTrending: true,
      isFineDining: true,
    ),
    const Restaurant(
      id: 'rest_3',
      name: 'Tatva Gourmet Vegetarian Fine Dining',
      tagline: 'Artisanal vegetarian gastronomy with royal touch',
      about:
          'Tatva redefines pure vegetarian dining with opulent interiors, exquisite plated global cuisines, and an ambiance suitable for grand family celebrations and intimate gourmet meals.',
      coverImageUrl:
          'https://images.unsplash.com/photo-1559339352-11d035aa65de?q=80&w=800&auto=format&fit=crop',
      galleryImages: [
        'https://images.unsplash.com/photo-1559339352-11d035aa65de?q=80&w=800&auto=format&fit=crop',
      ],
      rating: 4.7,
      reviewCount: 1600,
      cuisines: [CuisineType.northIndian, CuisineType.italian],
      priceForTwo: 1600,
      location: 'Road 36, Jubilee Hills',
      distance: '1.9 km',
      openingHours: '12:00 PM – 10:45 PM',
      isPureVeg: true,
      hasOutdoor: false,
      isOpenNow: true,
      offerBadge: '15% Off with IDFC First Cards',
      amenities: ['Pure Vegetarian', 'Private Dining Hall', 'Valet Parking', 'Wheelchair Accessible'],
      popularDishes: [
        DishItem(
          name: 'Paneer Lababdar Cannelloni',
          description: 'Baked pasta tubes filled with cottage cheese in spiced makhani reduction',
          price: 510,
          isVeg: true,
          isChefSpecial: true,
          imageUrl: 'https://images.unsplash.com/photo-1546833999-b9f581a1996d?q=80&w=400&auto=format&fit=crop',
        ),
      ],
      reviews: [
        DiningReview(
          userName: 'Suresh Agarwal',
          rating: 4.8,
          comment: 'Best pure veg restaurant in Hyderabad hands down. Luxurious interiors.',
          date: '3 days ago',
        ),
      ],
      availableSlots: [
        DiningTimeSlot(time: '12:45 PM', status: SlotAvailabilityStatus.available, tablesLeft: 5),
        DiningTimeSlot(time: '07:30 PM', status: SlotAvailabilityStatus.fillingFast, tablesLeft: 3),
        DiningTimeSlot(time: '09:00 PM', status: SlotAvailabilityStatus.available, tablesLeft: 4),
      ],
      isTrending: false,
      isFineDining: true,
    ),
    const Restaurant(
      id: 'rest_4',
      name: 'Jewel of Nizam – The Minar',
      tagline: 'Fifth floor tower fine-dining overlooking Osmansagar lake',
      about:
          'Located in a 100-foot heritage tower at The Golkonda Resort, Jewel of Nizam serves regal Hyderabadi culinary heritage, fragrant saffron biryanis, and Nizam-era kebabs.',
      coverImageUrl:
          'https://images.unsplash.com/photo-1544025162-d76694265947?q=80&w=800&auto=format&fit=crop',
      galleryImages: [
        'https://images.unsplash.com/photo-1544025162-d76694265947?q=80&w=800&auto=format&fit=crop',
      ],
      rating: 4.9,
      reviewCount: 3100,
      cuisines: [CuisineType.mughlai, CuisineType.telugu],
      priceForTwo: 3500,
      location: 'Golkonda Resorts, Gandipet',
      distance: '14 km',
      openingHours: '12:30 PM – 11:30 PM',
      isPureVeg: false,
      hasOutdoor: false,
      isOpenNow: true,
      offerBadge: 'VIP Chef’s Table Available',
      amenities: ['Panoramic Tower View', 'Royal Nizam Decor', 'Valet', 'Live Instrumental Music'],
      popularDishes: [
        DishItem(
          name: 'Nizami Dum Biryani',
          description: 'Slow sealed earthen pot fragrant long grain rice with tender spiced mutton',
          price: 890,
          isVeg: false,
          isChefSpecial: true,
          imageUrl: 'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?q=80&w=400&auto=format&fit=crop',
        ),
      ],
      reviews: [
        DiningReview(
          userName: 'Mirza Baig',
          rating: 5.0,
          comment: 'Authentic royal taste of old Hyderabad. Unbeatable ambiance at the top of the Minar.',
          date: '4 days ago',
        ),
      ],
      availableSlots: [
        DiningTimeSlot(time: '01:00 PM', status: SlotAvailabilityStatus.available, tablesLeft: 3),
        DiningTimeSlot(time: '07:45 PM', status: SlotAvailabilityStatus.fewTablesLeft, tablesLeft: 2),
        DiningTimeSlot(time: '09:15 PM', status: SlotAvailabilityStatus.fillingFast, tablesLeft: 3),
      ],
      isTrending: true,
      isFineDining: true,
    ),
    const Restaurant(
      id: 'rest_5',
      name: 'Roast CCX Coffee & Eatery',
      tagline: 'Artisanal single origin coffee & sourdough breakfast',
      about:
          'A sleek industrial glasshouse café in Hitec City known for its specialty coffee roastery, artisanal pastries, avocado toasts, and vibrant working vibe.',
      coverImageUrl:
          'https://images.unsplash.com/photo-1554118811-1e0d58224f24?q=80&w=800&auto=format&fit=crop',
      galleryImages: [
        'https://images.unsplash.com/photo-1554118811-1e0d58224f24?q=80&w=800&auto=format&fit=crop',
      ],
      rating: 4.7,
      reviewCount: 940,
      cuisines: [CuisineType.cafe, CuisineType.desserts],
      priceForTwo: 900,
      location: 'Knowledge City, Hitec City',
      distance: '3.8 km',
      openingHours: '08:00 AM – 11:00 PM',
      isPureVeg: false,
      hasOutdoor: true,
      isOpenNow: true,
      offerBadge: 'Free Coffee Upgrade before 11 AM',
      amenities: ['High Speed WiFi', 'Outdoor Deck', 'Pet Friendly', 'Power Outlets'],
      popularDishes: [
        DishItem(
          name: 'Spanish Latte & Basque Cheesecake',
          description: 'Condensed milk espresso with caramelized creamy burnt cheesecake slice',
          price: 450,
          isVeg: true,
          isChefSpecial: true,
          imageUrl: 'https://images.unsplash.com/photo-1509042239860-f550ce710b93?q=80&w=400&auto=format&fit=crop',
        ),
      ],
      reviews: [
        DiningReview(
          userName: 'Pooja Hegde',
          rating: 4.8,
          comment: 'Best specialty coffee in town. Very relaxing aesthetic with glass walls.',
          date: '5 days ago',
        ),
      ],
      availableSlots: [
        DiningTimeSlot(time: '10:00 AM', status: SlotAvailabilityStatus.available, tablesLeft: 8),
        DiningTimeSlot(time: '04:00 PM', status: SlotAvailabilityStatus.available, tablesLeft: 6),
        DiningTimeSlot(time: '07:30 PM', status: SlotAvailabilityStatus.fillingFast, tablesLeft: 4),
      ],
      isTrending: false,
      isFineDining: false,
    ),
  ];
}
