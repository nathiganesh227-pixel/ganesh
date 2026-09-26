import '../data/shopping_mock_data.dart';
import '../models/shopping.dart';
import 'shopping_repository.dart';

class LocalShoppingRepository implements ShoppingRepository {
  const LocalShoppingRepository();

  @override
  Future<List<Product>> getProducts({String? category, String? q, String? brand}) async {
    var list = ShoppingMockData.products;
    if (category != null && category.isNotEmpty && category.toLowerCase() != 'all') {
      final catLower = category.toLowerCase();
      list = list.where((p) =>
        p.category.label.toLowerCase() == catLower ||
        p.category.name.toLowerCase() == catLower ||
        p.category.label.toLowerCase().contains(catLower)
      ).toList();
    }
    if (brand != null && brand.isNotEmpty) {
      final brandLower = brand.toLowerCase();
      list = list.where((p) => p.brand.toLowerCase().contains(brandLower)).toList();
    }
    if (q != null && q.isNotEmpty) {
      final qLower = q.toLowerCase();
      list = list.where((p) =>
        p.name.toLowerCase().contains(qLower) ||
        p.brand.toLowerCase().contains(qLower) ||
        p.category.label.toLowerCase().contains(qLower) ||
        p.description.toLowerCase().contains(qLower) ||
        p.storeName.toLowerCase().contains(qLower)
      ).toList();
    }
    return list;
  }

  @override
  Future<Product?> getProductById(String id) async {
    try {
      return ShoppingMockData.products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<ShoppingStore>> getStores() async {
    return ShoppingMockData.stores;
  }

  @override
  Future<bool> createOrder(ShoppingOrder order) async {
    return true;
  }
}
