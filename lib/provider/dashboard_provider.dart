import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isLoading = false;
  String? _errorMessage;

  // Dashboard stats
  int _totalProducts = 0;
  int _totalCategories = 0;
  int _totalOrders = 0;
  double _totalRevenue = 0.0;
  int _pendingOrders = 0;
  int _lowStockProducts = 0;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get totalProducts => _totalProducts;
  int get totalCategories => _totalCategories;
  int get totalOrders => _totalOrders;
  double get totalRevenue => _totalRevenue;
  int get pendingOrders => _pendingOrders;
  int get lowStockProducts => _lowStockProducts;

  DashboardProvider() {
    loadDashboardStats();
  }

  Future<void> loadDashboardStats() async {
    try {
      _setLoading(true);
      _clearError();

      // Load all stats in parallel
      final futures = await Future.wait([
        _loadProductStats(),
        _loadCategoryStats(),
        _loadOrderStats(),
        _loadRevenueStats(),
      ]);

      notifyListeners();
    } catch (e) {
      _setError('Failed to load dashboard stats: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _loadProductStats() async {
    final productsResponse = await _supabase
        .from('products')
        .select('stock_quantity')
        .eq('is_active', true);

    _totalProducts = productsResponse.length;
    _lowStockProducts = productsResponse
        .where((product) => (product['stock_quantity'] as int) < 10)
        .length;
  }

  Future<void> _loadCategoryStats() async {
    final categoriesResponse = await _supabase
        .from('categories')
        .select('id')
        .eq('is_active', true);

    _totalCategories = categoriesResponse.length;
  }

  Future<void> _loadOrderStats() async {
    final ordersResponse = await _supabase.from('orders').select('status');

    _totalOrders = ordersResponse.length;
    _pendingOrders = ordersResponse
        .where((order) => order['status'] == 'pending')
        .length;
  }

  Future<void> _loadRevenueStats() async {
    final revenueResponse = await _supabase
        .from('orders')
        .select('total_amount')
        .eq('payment_status', 'paid');

    _totalRevenue = revenueResponse.fold(
      0.0,
      (sum, order) => sum + (order['total_amount'] as double),
    );
  }

  Future<List<Map<String, dynamic>>> getRecentOrders({int limit = 5}) async {
    try {
      final response = await _supabase
          .from('orders')
          .select('id, customer_email, total_amount, status, created_at')
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching recent orders: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getTopProducts({int limit = 5}) async {
    try {
      final response = await _supabase.rpc(
        'get_top_selling_products',
        params: {'limit_count': limit},
      );

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching top products: $e');
      return [];
    }
  }

  Future<Map<String, double>> getSalesAnalytics() async {
    try {
      final thirtyDaysAgo = DateTime.now().subtract(Duration(days: 30));

      final response = await _supabase
          .from('orders')
          .select('total_amount, created_at')
          .eq('payment_status', 'paid')
          .gte('created_at', thirtyDaysAgo.toIso8601String());

      Map<String, double> dailySales = {};

      for (var order in response) {
        final date = DateTime.parse(
          order['created_at'],
        ).toIso8601String().split('T')[0];
        dailySales[date] =
            (dailySales[date] ?? 0) + (order['total_amount'] as double);
      }

      return dailySales;
    } catch (e) {
      print('Error fetching sales analytics: $e');
      return {};
    }
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
}
