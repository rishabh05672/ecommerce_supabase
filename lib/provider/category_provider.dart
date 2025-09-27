import 'package:ecommerce_supabse/model/category_model.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CategoryProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<Category> _categories = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  CategoryProvider() {
    fetchCategories();
  }

  Future<void> fetchCategories() async {
    try {
      _setLoading(true);
      _clearError();

      final response = await _supabase
          .from('categories')
          .select()
          .order('created_at', ascending: false);

      _categories = (response as List)
          .map((category) => Category.fromJson(category))
          .toList();
    } catch (e) {
      _setError('Failed to fetch categories: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> addCategory(Category category) async {
    try {
      _setLoading(true);
      _clearError();

      final response = await _supabase
          .from('categories')
          .insert({
            'name': category.name,
            'description': category.description,
            'image_url': category.imageUrl,
            'is_active': category.isActive,
          })
          .select()
          .single();

      final newCategory = Category.fromJson(response);
      _categories.insert(0, newCategory);
      notifyListeners();

      return true;
    } catch (e) {
      _setError('Failed to add category: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateCategory(Category category) async {
    try {
      _setLoading(true);
      _clearError();

      await _supabase
          .from('categories')
          .update({
            'name': category.name,
            'description': category.description,
            'image_url': category.imageUrl,
            'is_active': category.isActive,
          })
          .eq('id', category.id);

      final index = _categories.indexWhere((c) => c.id == category.id);
      if (index != -1) {
        _categories[index] = category;
        notifyListeners();
      }

      return true;
    } catch (e) {
      _setError('Failed to update category: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteCategory(String categoryId) async {
    try {
      _setLoading(true);
      _clearError();

      // Check if category has products
      final productsCount = await _supabase
          .from('products')
          .select('id')
          .eq('category_id', categoryId)
          .count();

      if (productsCount.count > 0) {
        _setError('Cannot delete category with existing products');
        return false;
      }

      await _supabase.from('categories').delete().eq('id', categoryId);

      _categories.removeWhere((category) => category.id == categoryId);
      notifyListeners();

      return true;
    } catch (e) {
      _setError('Failed to delete category: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Category? getCategoryById(String id) {
    try {
      return _categories.firstWhere((category) => category.id == id);
    } catch (e) {
      return null;
    }
  }

  List<Category> getActiveCategories() {
    return _categories.where((category) => category.isActive).toList();
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
  void subscribeToCategories() {
    _supabase.from('categories').stream(primaryKey: ['id']).listen((data) {
      _categories = (data as List)
          .map((category) => Category.fromJson(category))
          .toList();
      notifyListeners();
    });
  }
}
