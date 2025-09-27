import 'package:ecommerce_supabse/model/order_model.dart';
import 'package:ecommerce_supabse/provider/order_provider.dart';
import 'package:ecommerce_supabse/utils/constants/supabase_key.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class OrderDetailsScreen extends StatelessWidget {
  final Order order;

  OrderDetailsScreen({required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order Details'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(context, value),
            itemBuilder: (context) => [
              PopupMenuItem(value: 'status', child: Text('Update Status')),
              PopupMenuItem(value: 'payment', child: Text('Update Payment')),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOrderHeader(),
            SizedBox(height: 20),
            _buildCustomerInfo(),
            SizedBox(height: 20),
            _buildOrderItems(),
            SizedBox(height: 20),
            _buildAddressInfo(),
            SizedBox(height: 20),
            _buildPricingBreakdown(),
            SizedBox(height: 20),
            _buildStatusHistory(),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderHeader() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${order.id.substring(0, 8)}',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(order.status),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    order.status.toUpperCase(),
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              'Order Date: ${DateFormat('MMM dd, yyyy HH:mm').format(order.createdAt)}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            Text(
              'Last Updated: ${DateFormat('MMM dd, yyyy HH:mm').format(order.updatedAt)}',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerInfo() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Customer Information',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            ListTile(
              leading: Icon(Icons.person),
              title: Text('Customer Email'),
              subtitle: Text(order.customerEmail),
              contentPadding: EdgeInsets.zero,
            ),
            ListTile(
              leading: Icon(Icons.payment),
              title: Text('Payment Status'),
              subtitle: Text(order.paymentStatus.toUpperCase()),
              trailing: Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getPaymentStatusColor(order.paymentStatus),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  order.paymentStatus.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItems() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Items (${order.items.length})',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            ...order.items.map((item) => _buildOrderItemTile(item)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItemTile(OrderItem item) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.inventory, color: Colors.grey),
      ),
      title: Text(
        item.productName,
        style: TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.productSku != null) Text('SKU: ${item.productSku}'),
          Text('Quantity: ${item.quantity}'),
          Text('Unit Price: ₹${item.unitPrice.toStringAsFixed(2)}'),
        ],
      ),
      trailing: Text(
        '₹${item.totalPrice.toStringAsFixed(2)}',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }

  Widget _buildAddressInfo() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Delivery Information',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            if (order.shippingAddress != null) ...[
              ListTile(
                leading: Icon(Icons.local_shipping),
                title: Text('Shipping Address'),
                subtitle: Text(_formatAddress(order.shippingAddress!)),
                contentPadding: EdgeInsets.zero,
              ),
            ],
            if (order.billingAddress != null) ...[
              ListTile(
                leading: Icon(Icons.receipt_long),
                title: Text('Billing Address'),
                subtitle: Text(_formatAddress(order.billingAddress!)),
                contentPadding: EdgeInsets.zero,
              ),
            ],
            if (order.notes?.isNotEmpty ?? false) ...[
              ListTile(
                leading: Icon(Icons.note),
                title: Text('Order Notes'),
                subtitle: Text(order.notes!),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPricingBreakdown() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Price Breakdown',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            _buildPriceRow(
              'Subtotal',
              order.totalAmount -
                  order.taxAmount -
                  order.shippingAmount +
                  order.discountAmount,
            ),
            if (order.discountAmount > 0)
              _buildPriceRow(
                'Discount',
                -order.discountAmount,
                isDiscount: true,
              ),
            if (order.taxAmount > 0) _buildPriceRow('Tax', order.taxAmount),
            if (order.shippingAmount > 0)
              _buildPriceRow('Shipping', order.shippingAmount),
            Divider(),
            _buildPriceRow('Total', order.totalAmount, isTotal: true),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(
    String label,
    double amount, {
    bool isDiscount = false,
    bool isTotal = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '₹${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isDiscount ? Colors.green : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusHistory() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Timeline',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            _buildTimelineItem('Order Created', order.createdAt, true),
            if (order.status != 'pending')
              _buildTimelineItem(
                'Status: ${order.status.toUpperCase()}',
                order.updatedAt,
                true,
              ),
            if (order.paymentStatus == 'paid')
              _buildTimelineItem('Payment Confirmed', order.updatedAt, true),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(String title, DateTime date, bool isCompleted) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: isCompleted ? Colors.green : Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.w500)),
                Text(
                  DateFormat('MMM dd, yyyy HH:mm').format(date),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'status':
        _showStatusUpdateDialog(context);
        break;
      case 'payment':
        _showPaymentUpdateDialog(context);
        break;
    }
  }

  void _showStatusUpdateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Order Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppConstants.orderStatuses.map((status) {
            final isCurrentStatus = status == order.status;
            return ListTile(
              title: Text(
                status.toUpperCase(),
                style: TextStyle(
                  fontWeight: isCurrentStatus
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: isCurrentStatus ? Colors.blue : Colors.black,
                ),
              ),
              trailing: isCurrentStatus
                  ? Icon(Icons.check, color: Colors.blue)
                  : null,
              onTap: isCurrentStatus
                  ? null
                  : () async {
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

                      if (success) {
                        Navigator.pop(
                          context,
                        ); // Go back to refresh the details
                      }
                    },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showPaymentUpdateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Payment Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppConstants.paymentStatuses.map((status) {
            final isCurrentStatus = status == order.paymentStatus;
            return ListTile(
              title: Text(
                status.toUpperCase(),
                style: TextStyle(
                  fontWeight: isCurrentStatus
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: isCurrentStatus ? Colors.blue : Colors.black,
                ),
              ),
              trailing: isCurrentStatus
                  ? Icon(Icons.check, color: Colors.blue)
                  : null,
              onTap: isCurrentStatus
                  ? null
                  : () async {
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

                      if (success) {
                        Navigator.pop(
                          context,
                        ); // Go back to refresh the details
                      }
                    },
            );
          }).toList(),
        ),
      ),
    );
  }

  String _formatAddress(Map<String, dynamic> address) {
    List<String> parts = [];
    if (address['address_line_1'] != null) parts.add(address['address_line_1']);
    if (address['address_line_2'] != null) parts.add(address['address_line_2']);
    if (address['city'] != null) parts.add(address['city']);
    if (address['state'] != null) parts.add(address['state']);
    if (address['postal_code'] != null) parts.add(address['postal_code']);
    if (address['country'] != null) parts.add(address['country']);

    return parts.join(', ');
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

  Color _getPaymentStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      case 'refunded':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}
