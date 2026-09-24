import '../data/shopping_mock_data.dart';
import '../models/shopping.dart';
import 'shopping_repository.dart';

class LocalShoppingRepository implements ShoppingRepository {
  const LocalShoppingRepository();

  @override
  Future<List<Product>> getProducts({String? category}) async {
    final list = ShoppingMockData.products;
    if (category == null || category.isEmpty || category.toLowerCase() == 'all') {
      return list;
    }
    return list.where((p) => p.category.label.toLowerCase() == category.toLowerCase() || p.category.name.toLowerCase() == category.toLowerCase()).toList();
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
