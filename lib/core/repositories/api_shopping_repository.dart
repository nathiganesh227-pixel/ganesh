import '../models/shopping.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';
import 'shopping_repository.dart';
import 'local_shopping_repository.dart';

class ApiShoppingRepository implements ShoppingRepository {
  final ApiClient _client;
  final LocalShoppingRepository _fallback;

  ApiShoppingRepository({
    ApiClient? client,
    LocalShoppingRepository? fallback,
  })  : _client = client ?? ApiClient(),
        _fallback = fallback ?? const LocalShoppingRepository();

  @override
  Future<List<Product>> getProducts({String? category}) async {
    try {
      final response = await _client.get<List<Product>>(
        ApiEndpoints.shopping,
        queryParams: (category != null && category.isNotEmpty && category.toLowerCase() != 'all')
            ? {'category': category}
            : null,
        fromJson: (json) {
          if (json is List) {
            return json
                .map((item) => Product.fromJson(item as Map<String, dynamic>))
                .toList();
          }
          return [];
        },
      );

      if (response.success && response.data != null && response.data!.isNotEmpty) {
        return response.data!;
      }
    } catch (_) {}
    return _fallback.getProducts(category: category);
  }

  @override
  Future<Product?> getProductById(String id) async {
    try {
      final response = await _client.get<Product?>(
        ApiEndpoints.productDetails(id),
        fromJson: (json) => json != null
            ? Product.fromJson(json as Map<String, dynamic>)
            : null,
      );

      if (response.success && response.data != null) {
        return response.data;
      }
    } catch (_) {}
    return _fallback.getProductById(id);
  }

  @override
  Future<List<ShoppingStore>> getStores() async {
    return _fallback.getStores();
  }

  @override
  Future<bool> createOrder(ShoppingOrder order) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/bookings/shopping',
        body: {
          'items': order.items.map((item) => {
            'productId': item.product.id,
            'variantId': item.selectedVariant?.id,
            'quantity': item.quantity,
          }).toList(),
          'fulfillmentType': order.fulfillmentType.label,
        },
        fromJson: (json) => json as Map<String, dynamic>,
      );
      if (response.success) {
        await _fallback.createOrder(order);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
