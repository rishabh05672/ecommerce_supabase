import 'package:ecommerce_supabse/model/order_model.dart';
import 'package:ecommerce_supabse/utils/constants/supabase_key.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OrderProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<Order> _orders = [];
  List<Order> _filteredOrders = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedStatusFilter = 'All';

  List<Order> get orders => _filteredOrders.isEmpty ? _orders : _filteredOrders;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get selectedStatusFilter => _selectedStatusFilter;

  double get totalRevenue => _orders
      .where((order) => order.paymentStatus == 'paid')
      .fold(0.0, (sum, order) => sum + order.totalAmount);

  int get totalOrders => _orders.length;
  int get pendingOrders => _orders.where((o) => o.status == 'pending').length;
  int get completedOrders =>
      _orders.where((o) => o.status == 'delivered').length;

  OrderProvider() {
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    try {
      _setLoading(true);
      _clearError();

      final response = await _supabase
          .from('orders')
          .select('*, order_items(*)')
          .order('created_at', ascending: false);

      _orders = (response as List)
          .map((order) => Order.fromJson(order))
          .toList();

      _applyFilters();
    } catch (e) {
      _setError('Failed to fetch orders: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateOrderStatus(String orderId, String status) async {
    try {
      _setLoading(true);
      _clearError();

      await _supabase
          .from('orders')
          .update({'status': status})
          .eq('id', orderId);

      final index = _orders.indexWhere((order) => order.id == orderId);
      if (index != -1) {
        final updatedOrder = Order.fromJson({
          ..._orders[index].toJson(),
          'status': status,
          'updated_at': DateTime.now().toIso8601String(),
        });
        _orders[index] = updatedOrder;
        _applyFilters();
      }

      return true;
    } catch (e) {
      _setError('Failed to update order status: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updatePaymentStatus(String orderId, String paymentStatus) async {
    try {
      _setLoading(true);
      _clearError();

      await _supabase
          .from('orders')
          .update({'payment_status': paymentStatus})
          .eq('id', orderId);

      final index = _orders.indexWhere((order) => order.id == orderId);
      if (index != -1) {
        final updatedOrder = Order.fromJson({
          ..._orders[index].toJson(),
          'payment_status': paymentStatus,
          'updated_at': DateTime.now().toIso8601String(),
        });
        _orders[index] = updatedOrder;
        _applyFilters();
      }

      return true;
    } catch (e) {
      _setError('Failed to update payment status: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void filterByStatus(String status) {
    _selectedStatusFilter = status;
    _applyFilters();
  }

  void _applyFilters() {
    List<Order> filtered = List.from(_orders);

    if (_selectedStatusFilter != 'All') {
      filtered = filtered
          .where((order) => order.status == _selectedStatusFilter.toLowerCase())
          .toList();
    }

    _filteredOrders = filtered;
    notifyListeners();
  }

  void clearFilters() {
    _selectedStatusFilter = 'All';
    _filteredOrders.clear();
    notifyListeners();
  }

  Order? getOrderById(String orderId) {
    try {
      return _orders.firstWhere((order) => order.id == orderId);
    } catch (e) {
      return null;
    }
  }

  List<Order> getOrdersByDateRange(DateTime startDate, DateTime endDate) {
    return _orders
        .where(
          (order) =>
              order.createdAt.isAfter(startDate) &&
              order.createdAt.isBefore(endDate),
        )
        .toList();
  }

  Map<String, int> getOrderStatusCounts() {
    Map<String, int> statusCounts = {};

    for (String status in AppConstants.orderStatuses) {
      statusCounts[status] = _orders
          .where((order) => order.status == status)
          .length;
    }

    return statusCounts;
  }

  Map<String, double> getRevenueByMonth() {
    Map<String, double> monthlyRevenue = {};

    for (Order order in _orders.where((o) => o.paymentStatus == 'paid')) {
      String monthKey =
          '${order.createdAt.year}-${order.createdAt.month.toString().padLeft(2, '0')}';
      monthlyRevenue[monthKey] =
          (monthlyRevenue[monthKey] ?? 0) + order.totalAmount;
    }

    return monthlyRevenue;
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
  void subscribeToOrders() {
    _supabase.from('orders').stream(primaryKey: ['id']).listen((data) {
      _orders = (data as List).map((order) => Order.fromJson(order)).toList();
      _applyFilters();
    });
  }
}
