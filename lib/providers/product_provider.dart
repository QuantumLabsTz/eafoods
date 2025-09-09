import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../models/stock_update.dart';
import '../services/database_service.dart';

class ProductProvider with ChangeNotifier {
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _sortBy = 'name';
  bool _isLoading = false;
  String? _error;

  List<Product> get products => _products;
  List<Product> get filteredProducts => _filteredProducts;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<String> get categories {
    final categories = _products.map((p) => p.category).toSet().toList();
    return ['All', ...categories];
  }

  List<Product> get lowStockProducts =>
      _products.where((p) => p.stockQuantity < 10).toList();
  List<Product> get outOfStockProducts =>
      _products.where((p) => p.stockQuantity == 0).toList();

  Future<void> loadProducts() async {
    _setLoading(true);
    _clearError();

    try {
      _products = await DatabaseService.getAllProducts();
      _applyFilters();
    } catch (e) {
      _setError('Failed to load products: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> searchProducts(String query) async {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  void filterByCategory(String category) {
    _selectedCategory = category;
    _applyFilters();
    notifyListeners();
  }

  void sortProducts(String sortBy) {
    _sortBy = sortBy;
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    List<Product> filtered = _products;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (product) =>
                product.name.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                product.description.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ),
          )
          .toList();
    }

    // Apply category filter
    if (_selectedCategory != 'All') {
      filtered = filtered
          .where((product) => product.category == _selectedCategory)
          .toList();
    }

    // Apply sorting
    switch (_sortBy) {
      case 'name':
        filtered.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'stock':
        filtered.sort((a, b) => b.stockQuantity.compareTo(a.stockQuantity));
        break;
      case 'category':
        filtered.sort((a, b) => a.category.compareTo(b.category));
        break;
    }

    _filteredProducts = filtered;
  }

  Future<bool> updateProductStock({
    required String productId,
    required int newStock,
    required String updatedBy,
    String? notes,
  }) async {
    try {
      final product = await DatabaseService.getProduct(productId);
      if (product == null) return false;

      await DatabaseService.updateProductStock(productId, newStock);

      // Save stock update record
      final stockUpdate = StockUpdate(
        productId: productId,
        productName: product.name,
        oldQuantity: product.stockQuantity,
        newQuantity: newStock,
        updateType: DateTime.now().hour < 12
            ? StockUpdateType.morning
            : StockUpdateType.evening,
        reason: notes,
      );
      await DatabaseService.saveStockUpdate(stockUpdate);

      await loadProducts(); // Reload products to reflect changes
      return true;
    } catch (e) {
      _setError('Failed to update stock: ${e.toString()}');
      return false;
    }
  }

  Product? getProductById(String id) {
    try {
      return _products.firstWhere((product) => product.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<void> syncWithServer() async {
    _setLoading(true);
    _clearError();

    try {
      // For now, just reload products from database
      // In a real app, this would sync with a remote server
      await loadProducts();
    } catch (e) {
      _setError('Sync error: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedCategory = 'All';
    _sortBy = 'name';
    _applyFilters();
    notifyListeners();
  }
}
