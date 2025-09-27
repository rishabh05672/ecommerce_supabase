// ignore_for_file: use_build_context_synchronously, use_key_in_widget_constructors

import 'package:ecommerce_supabse/model/order_model.dart';
import 'package:ecommerce_supabse/provider/order_provider.dart';
import 'package:ecommerce_supabse/screen/order_detail_screen.dart';
import 'package:ecommerce_supabse/utils/constants/supabase_key.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class OrdersScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildFilterSection(context),
        Expanded(
          child: Consumer<OrderProvider>(
            builder: (context, orderProvider, child) {
              if (orderProvider.isLoading) {
                return Center(child: CircularProgressIndicator());
              }

              if (orderProvider.errorMessage != null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: ${orderProvider.errorMessage}'),
                      ElevatedButton(
                        onPressed: () => orderProvider.fetchOrders(),
                        child: Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              final orders = orderProvider.orders;

              if (orders.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_cart, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No orders found'),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () => orderProvider.fetchOrders(),
                child: ListView.builder(
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return _buildOrderCard(context, order);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterSection(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          Text('Filter: '),
          Expanded(
            child: Consumer<OrderProvider>(
              builder: (context, orderProvider, child) {
                return DropdownButton<String>(
                  isExpanded: true,
                  value: orderProvider.selectedStatusFilter,
                  onChanged: (String? status) {
                    if (status != null) {
                      orderProvider.filterByStatus(status);
                    }
                  },
                  items: [
                    DropdownMenuItem(value: 'All', child: Text('All Orders')),
                    ...AppConstants.orderStatuses.map(
                      (status) => DropdownMenuItem(
                        value: status,
                        child: Text(status.toUpperCase()),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, Order order) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: _getStatusColor(order.status),
            shape: BoxShape.circle,
          ),
          child: Icon(_getStatusIcon(order.status), color: Colors.white),
        ),
        title: Text(
          'Order #${order.id.substring(0, 8)}',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Customer: ${order.customerEmail}'),
            Text('Amount: ₹${order.totalAmount.toStringAsFixed(2)}'),
            Text('Status: ${order.status.toUpperCase()}'),
            Text('Date: ${DateFormat('MMM dd, yyyy').format(order.createdAt)}'),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleOrderAction(context, value, order),
          itemBuilder: (context) => [
            PopupMenuItem(value: 'view', child: Text('View Details')),
            PopupMenuItem(value: 'status', child: Text('Update Status')),
            PopupMenuItem(value: 'payment', child: Text('Update Payment')),
          ],
        ),
        onTap: () => _navigateToOrderDetails(context, order),
      ),
    );
  }

  void _handleOrderAction(BuildContext context, String action, Order order) {
    switch (action) {
      case 'view':
        _navigateToOrderDetails(context, order);
        break;
      case 'status':
        _showStatusUpdateDialog(context, order);
        break;
      case 'payment':
        _showPaymentUpdateDialog(context, order);
        break;
    }
  }

  void _showStatusUpdateDialog(BuildContext context, Order order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Order Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppConstants.orderStatuses.map((status) {
            return ListTile(
              title: Text(status.toUpperCase()),
              onTap: () async {
                Navigator.pop(context);
                final success = await context
                    .read<OrderProvider>()
                    .updateOrderStatus(order.id, status);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Status updated successfully'
                          : 'Failed to update status',
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showPaymentUpdateDialog(BuildContext context, Order order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Payment Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppConstants.paymentStatuses.map((status) {
            return ListTile(
              title: Text(status.toUpperCase()),
              onTap: () async {
                Navigator.pop(context);
                final success = await context
                    .read<OrderProvider>()
                    .updatePaymentStatus(order.id, status);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Payment status updated successfully'
                          : 'Failed to update payment status',
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _navigateToOrderDetails(BuildContext context, Order order) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => OrderDetailsScreen(order: order)),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'processing':
        return Colors.purple;
      case 'shipped':
        return Colors.teal;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'refunded':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.pending;
      case 'confirmed':
        return Icons.check_circle;
      case 'processing':
        return Icons.settings;
      case 'shipped':
        return Icons.local_shipping;
      case 'delivered':
        return Icons.done_all;
      case 'cancelled':
        return Icons.cancel;
      case 'refunded':
        return Icons.money_off;
      default:
        return Icons.help;
    }
  }
}
