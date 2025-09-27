class Order {
  final String id;
  final String? customerId;
  final String customerEmail;
  final double totalAmount;
  final double taxAmount;
  final double shippingAmount;
  final double discountAmount;
  final String status;
  final String paymentStatus;
  final Map<String, dynamic>? shippingAddress;
  final Map<String, dynamic>? billingAddress;
  final String? notes;
  final List<OrderItem> items;
  final DateTime createdAt;
  final DateTime updatedAt;

  Order({
    required this.id,
    this.customerId,
    required this.customerEmail,
    required this.totalAmount,
    required this.taxAmount,
    required this.shippingAmount,
    required this.discountAmount,
    required this.status,
    required this.paymentStatus,
    this.shippingAddress,
    this.billingAddress,
    this.notes,
    required this.items,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      customerId: json['customer_id'],
      customerEmail: json['customer_email'],
      totalAmount: json['total_amount'].toDouble(),
      taxAmount: json['tax_amount']?.toDouble() ?? 0.0,
      shippingAmount: json['shipping_amount']?.toDouble() ?? 0.0,
      discountAmount: json['discount_amount']?.toDouble() ?? 0.0,
      status: json['status'],
      paymentStatus: json['payment_status'],
      shippingAddress: json['shipping_address'],
      billingAddress: json['billing_address'],
      notes: json['notes'],
      items:
          (json['order_items'] as List<dynamic>?)
              ?.map((item) => OrderItem.fromJson(item))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  // toJson method for API calls and data serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'customer_email': customerEmail,
      'total_amount': totalAmount,
      'tax_amount': taxAmount,
      'shipping_amount': shippingAmount,
      'discount_amount': discountAmount,
      'status': status,
      'payment_status': paymentStatus,
      'shipping_address': shippingAddress,
      'billing_address': billingAddress,
      'notes': notes,
      'order_items': items.map((item) => item.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // copyWith method for immutable updates in Provider
  Order copyWith({
    String? id,
    String? customerId,
    String? customerEmail,
    double? totalAmount,
    double? taxAmount,
    double? shippingAmount,
    double? discountAmount,
    String? status,
    String? paymentStatus,
    Map<String, dynamic>? shippingAddress,
    Map<String, dynamic>? billingAddress,
    String? notes,
    List<OrderItem>? items,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Order(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerEmail: customerEmail ?? this.customerEmail,
      totalAmount: totalAmount ?? this.totalAmount,
      taxAmount: taxAmount ?? this.taxAmount,
      shippingAmount: shippingAmount ?? this.shippingAmount,
      discountAmount: discountAmount ?? this.discountAmount,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      billingAddress: billingAddress ?? this.billingAddress,
      notes: notes ?? this.notes,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper methods for calculations
  double get subtotal =>
      totalAmount - taxAmount - shippingAmount + discountAmount;
  double get finalAmount => totalAmount;
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);
  bool get isPaid => paymentStatus.toLowerCase() == 'paid';
  bool get isCompleted => status.toLowerCase() == 'delivered';
  bool get isCancelled => status.toLowerCase() == 'cancelled';

  @override
  String toString() {
    return 'Order{id: $id, customerEmail: $customerEmail, status: $status, totalAmount: $totalAmount}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Order && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class OrderItem {
  final String id;
  final String orderId;
  final String? productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final String? productSku;

  OrderItem({
    required this.id,
    required this.orderId,
    this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.productSku,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'],
      orderId: json['order_id'],
      productId: json['product_id'],
      productName: json['product_name'],
      quantity: json['quantity'],
      unitPrice: json['unit_price'].toDouble(),
      totalPrice: json['total_price'].toDouble(),
      productSku: json['product_sku'],
    );
  }

  // toJson method for OrderItem
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'product_id': productId,
      'product_name': productName,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_price': totalPrice,
      'product_sku': productSku,
    };
  }

  // copyWith method for OrderItem
  OrderItem copyWith({
    String? id,
    String? orderId,
    String? productId,
    String? productName,
    int? quantity,
    double? unitPrice,
    double? totalPrice,
    String? productSku,
  }) {
    return OrderItem(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      totalPrice: totalPrice ?? this.totalPrice,
      productSku: productSku ?? this.productSku,
    );
  }

  // Helper methods
  double get discountAmount => (unitPrice * quantity) - totalPrice;
  bool get hasDiscount => discountAmount > 0;

  @override
  String toString() {
    return 'OrderItem{id: $id, productName: $productName, quantity: $quantity, totalPrice: $totalPrice}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OrderItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
