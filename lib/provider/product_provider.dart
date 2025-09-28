// ignore_for_file: unnecessary_overrides

import 'package:ecommerce_supabse/model/product_model.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProductProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  String _selectedCategoryFilter = 'All';

  List<Product> get products =>
      _filteredProducts.isEmpty ? _products : _filteredProducts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String get selectedCategoryFilter => _selectedCategoryFilter;

  ProductProvider() {
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    try {
      _setLoading(true);
      _clearError();

      final response = await _supabase
          .from('products')
          .select('*, categories(name)')
          .order('created_at', ascending: false);

      _products = (response as List)
          .map((product) => Product.fromJson(product))
          .toList();

      _applyFilters();
    } catch (e) {
      _setError('Failed to fetch products: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> addProduct(Product product) async {
    try {
      _setLoading(true);
      _clearError();

      final response = await _supabase
          .from('products')
          .insert({
            'name': product.name,
            'description': product.description,
            'price': product.price,
            'discount_price': product.discountPrice,
            'category_id': product.categoryId,
            'stock_quantity': product.stockQuantity,
            'images': product.images,
            'sku': product.sku,
            'is_active': product.isActive,
          })
          .select()
          .single();

      final newProduct = Product.fromJson(response);
      _products.insert(0, newProduct);
      _applyFilters();

      return true;
    } catch (e) {
      _setError('Failed to add product: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateProduct(Product product) async {
    try {
      _setLoading(true);
      _clearError();

      await _supabase
          .from('products')
          .update({
            'name': product.name,
            'description': product.description,
            'price': product.price,
            'discount_price': product.discountPrice,
            'category_id': product.categoryId,
            'stock_quantity': product.stockQuantity,
            'images': product.images,
            'sku': product.sku,
            'is_active': product.isActive,
          })
          .eq('id', product.id);

      final index = _products.indexWhere((p) => p.id == product.id);
      if (index != -1) {
        _products[index] = product;
        _applyFilters();
      }

      return true;
    } catch (e) {
      _setError('Failed to update product: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteProduct(String productId) async {
    try {
      _setLoading(true);
      _clearError();

      await _supabase.from('products').delete().eq('id', productId);

      _products.removeWhere((product) => product.id == productId);
      _applyFilters();

      return true;
    } catch (e) {
      _setError('Failed to delete product: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void searchProducts(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  void filterByCategory(String categoryId) {
    _selectedCategoryFilter = categoryId;
    _applyFilters();
  }

  void _applyFilters() {
    List<Product> filtered = List.from(_products);

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
                ) ||
                (product.sku?.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ??
                    false),
          )
          .toList();
    }

    // Apply category filter
    if (_selectedCategoryFilter != 'All') {
      filtered = filtered
          .where((product) => product.categoryId == _selectedCategoryFilter)
          .toList();
    }

    _filteredProducts = filtered;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedCategoryFilter = 'All';
    _filteredProducts.clear();
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void clearError() {
    _clearError();
    notifyListeners();
  }

  // Real-time subscription
  void subscribeToProducts() {
    _supabase.from('products').stream(primaryKey: ['id']).listen((data) {
      _products = (data as List)
          .map((product) => Product.fromJson(product))
          .toList();
      _applyFilters();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }
}
