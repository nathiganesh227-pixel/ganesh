import '../models/shopping.dart';

abstract class ShoppingRepository {
  Future<List<Product>> getProducts({String? category, String? q, String? brand});
  Future<Product?> getProductById(String id);
  Future<List<ShoppingStore>> getStores();
  Future<bool> createOrder(ShoppingOrder order);
}
