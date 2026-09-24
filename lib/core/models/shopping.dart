enum ShoppingCategoryType {
  fashion('Fashion & Apparel', '👗'),
  electronics('Electronics & Tech', '⚡'),
  beauty('Beauty & Fragrance', '✨'),
  home('Home & Living', '🛋️'),
  lifestyle('Luxury & Lifestyle', '💎'),
  footwear('Sneakers & Shoes', '👟'),
  accessories('Watches & Accessories', '⌚'),
  malls('Malls & Flagships', '🏬');

  final String label;
  final String emoji;
  const ShoppingCategoryType(this.label, this.emoji);

  static ShoppingCategoryType fromString(String val) {
    return ShoppingCategoryType.values.firstWhere(
      (e) =>
          e.name.toLowerCase() == val.toLowerCase() ||
          e.label.toLowerCase() == val.toLowerCase(),
      orElse: () => ShoppingCategoryType.lifestyle,
    );
  }
}

class ProductVariant {
  final String id;
  final String name; // e.g., "Size: M", "Color: Midnight Black", "256 GB"
  final double priceDelta;
  final bool inStock;

  const ProductVariant({
    required this.id,
    required this.name,
    this.priceDelta = 0.0,
    this.inStock = true,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      priceDelta: (json['priceDelta'] as num?)?.toDouble() ?? 0.0,
      inStock: json['inStock'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'priceDelta': priceDelta,
    'inStock': inStock,
  };
}

class Product {
  final String id;
  final String name;
  final String brand;
  final ShoppingCategoryType category;
  final double price;
  final double? originalPrice;
  final double rating;
  final int reviewCount;
  final String coverImageUrl;
  final List<String> galleryImages;
  final String description;
  final Map<String, String> specifications;
  final List<ProductVariant> variants;
  final String storeId;
  final String storeName;
  final String storeLocation;
  final String distance;
  final bool isTrending;
  final bool isDealOfTheDay;
  final String? discountBadge;
  final bool inStock;

  const Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.category,
    required this.price,
    this.originalPrice,
    required this.rating,
    required this.reviewCount,
    required this.coverImageUrl,
    required this.galleryImages,
    required this.description,
    required this.specifications,
    required this.variants,
    required this.storeId,
    required this.storeName,
    required this.storeLocation,
    required this.distance,
    this.isTrending = false,
    this.isDealOfTheDay = false,
    this.discountBadge,
    this.inStock = true,
  });

  double get discountPercent {
    if (originalPrice == null || originalPrice! <= price) return 0;
    return ((originalPrice! - price) / originalPrice!) * 100;
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      brand: json['brand'] as String? ?? '',
      category: ShoppingCategoryType.fromString(json['category'] as String? ?? ''),
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      originalPrice: (json['originalPrice'] as num?)?.toDouble(),
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      coverImageUrl: json['coverImageUrl'] as String? ?? '',
      galleryImages: (json['galleryImages'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      description: json['description'] as String? ?? '',
      specifications: (json['specifications'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, v.toString()),
          ) ??
          {},
      variants: (json['variants'] as List<dynamic>?)
              ?.map((e) => ProductVariant.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      storeId: json['storeId'] as String? ?? '',
      storeName: json['storeName'] as String? ?? '',
      storeLocation: json['storeLocation'] as String? ?? '',
      distance: json['distance'] as String? ?? '',
      isTrending: json['isTrending'] as bool? ?? false,
      isDealOfTheDay: json['isDealOfTheDay'] as bool? ?? false,
      discountBadge: json['discountBadge'] as String?,
      inStock: json['inStock'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'brand': brand,
    'category': category.name,
    'price': price,
    'originalPrice': originalPrice,
    'rating': rating,
    'reviewCount': reviewCount,
    'coverImageUrl': coverImageUrl,
    'galleryImages': galleryImages,
    'description': description,
    'specifications': specifications,
    'variants': variants.map((v) => v.toJson()).toList(),
    'storeId': storeId,
    'storeName': storeName,
    'storeLocation': storeLocation,
    'distance': distance,
    'isTrending': isTrending,
    'isDealOfTheDay': isDealOfTheDay,
    'discountBadge': discountBadge,
    'inStock': inStock,
  };
}

class ShoppingStore {
  final String id;
  final String name;
  final String mallName;
  final String location;
  final String distance;
  final double rating;
  final String coverImageUrl;
  final String openingHours;
  final List<ShoppingCategoryType> categories;
  final String offerTag;
  final String contactNumber;
  final String floorLocation;

  const ShoppingStore({
    required this.id,
    required this.name,
    required this.mallName,
    required this.location,
    required this.distance,
    required this.rating,
    required this.coverImageUrl,
    required this.openingHours,
    required this.categories,
    required this.offerTag,
    required this.contactNumber,
    required this.floorLocation,
  });

  factory ShoppingStore.fromJson(Map<String, dynamic> json) {
    return ShoppingStore(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      mallName: json['mallName'] as String? ?? '',
      location: json['location'] as String? ?? '',
      distance: json['distance'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      coverImageUrl: json['coverImageUrl'] as String? ?? '',
      openingHours: json['openingHours'] as String? ?? '',
      categories: (json['categories'] as List<dynamic>?)
              ?.map((e) => ShoppingCategoryType.fromString(e.toString()))
              .toList() ??
          [],
      offerTag: json['offerTag'] as String? ?? '',
      contactNumber: json['contactNumber'] as String? ?? '',
      floorLocation: json['floorLocation'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'mallName': mallName,
    'location': location,
    'distance': distance,
    'rating': rating,
    'coverImageUrl': coverImageUrl,
    'openingHours': openingHours,
    'categories': categories.map((e) => e.name).toList(),
    'offerTag': offerTag,
    'contactNumber': contactNumber,
    'floorLocation': floorLocation,
  };
}

class CartItem {
  final Product product;
  final ProductVariant? selectedVariant;
  int quantity;

  CartItem({
    required this.product,
    this.selectedVariant,
    this.quantity = 1,
  });

  double get unitPrice => product.price + (selectedVariant?.priceDelta ?? 0);
  double get totalPrice => unitPrice * quantity;

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      product: Product.fromJson(json['product'] as Map<String, dynamic>),
      selectedVariant: json['selectedVariant'] != null
          ? ProductVariant.fromJson(json['selectedVariant'] as Map<String, dynamic>)
          : null,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
    'product': product.toJson(),
    'selectedVariant': selectedVariant?.toJson(),
    'quantity': quantity,
  };
}

enum ShoppingFulfillmentType {
  inStorePickup('Express Store Pickup (Ready in 2h)', '🏬'),
  standardDelivery('Premium Express Delivery (Same Day)', '🚀');

  final String label;
  final String icon;
  const ShoppingFulfillmentType(this.label, this.icon);

  static ShoppingFulfillmentType fromString(String val) {
    return ShoppingFulfillmentType.values.firstWhere(
      (e) =>
          e.name.toLowerCase() == val.toLowerCase() ||
          e.label.toLowerCase() == val.toLowerCase(),
      orElse: () => ShoppingFulfillmentType.inStorePickup,
    );
  }
}

class ShoppingOrder {
  final String orderId;
  final List<CartItem> items;
  final double itemsTotal;
  final double discountAmount;
  final double platformFee;
  final double gstAmount;
  final double grandTotal;
  final ShoppingFulfillmentType fulfillmentType;
  final String storeName;
  final String storeLocation;
  final DateTime orderTime;
  final String qrCodeData;
  final String paymentMethod;
  final String pickupCode;

  const ShoppingOrder({
    required this.orderId,
    required this.items,
    required this.itemsTotal,
    required this.discountAmount,
    required this.platformFee,
    required this.gstAmount,
    required this.grandTotal,
    required this.fulfillmentType,
    required this.storeName,
    required this.storeLocation,
    required this.orderTime,
    required this.qrCodeData,
    required this.paymentMethod,
    required this.pickupCode,
  });

  factory ShoppingOrder.fromJson(Map<String, dynamic> json) {
    return ShoppingOrder(
      orderId: json['orderId'] as String? ?? json['id'] as String? ?? '',
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => CartItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      itemsTotal: (json['itemsTotal'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0.0,
      platformFee: (json['platformFee'] as num?)?.toDouble() ?? 29.0,
      gstAmount: (json['gstAmount'] as num?)?.toDouble() ?? 0.0,
      grandTotal: (json['grandTotal'] as num?)?.toDouble() ??
          (json['totalPrice'] as num?)?.toDouble() ??
          0.0,
      fulfillmentType: ShoppingFulfillmentType.fromString(
        json['fulfillmentType'] as String? ?? 'inStorePickup',
      ),
      storeName: json['storeName'] as String? ?? json['title'] as String? ?? '',
      storeLocation: json['storeLocation'] as String? ??
          json['location'] as String? ??
          '',
      orderTime: json['orderTime'] != null
          ? DateTime.tryParse(json['orderTime'].toString()) ?? DateTime.now()
          : DateTime.now(),
      qrCodeData: json['qrCodeData'] as String? ?? '',
      paymentMethod: json['paymentMethod'] as String? ?? 'Apple Pay',
      pickupCode: json['pickupCode'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'orderId': orderId,
    'items': items.map((e) => e.toJson()).toList(),
    'itemsTotal': itemsTotal,
    'discountAmount': discountAmount,
    'platformFee': platformFee,
    'gstAmount': gstAmount,
    'grandTotal': grandTotal,
    'fulfillmentType': fulfillmentType.name,
    'storeName': storeName,
    'storeLocation': storeLocation,
    'orderTime': orderTime.toIso8601String(),
    'qrCodeData': qrCodeData,
    'paymentMethod': paymentMethod,
    'pickupCode': pickupCode,
  };
}
