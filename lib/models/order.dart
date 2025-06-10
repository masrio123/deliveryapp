// models/order_model.dart
class Order {
  final int orderId;
  final int cartId;
  final int customerId;
  final String customerName;
  final int tenantLocationId;
  final String tenantLocationName;
  final String orderStatus;
  final List<OrderItem> items;
  final int totalPrice;
  final int shippingCost;
  final int grandTotal;

  Order({
    required this.orderId,
    required this.cartId,
    required this.customerId,
    required this.customerName,
    required this.tenantLocationId,
    required this.tenantLocationName,
    required this.orderStatus,
    required this.items,
    required this.totalPrice,
    required this.shippingCost,
    required this.grandTotal,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      orderId: json['order_id'],
      cartId: json['cart_id'],
      customerId: json['customer_id'],
      customerName: json['customer_name'],
      tenantLocationId: json['tenant_location_id'],
      tenantLocationName: json['tenant_location_name'],
      orderStatus: json['order_status'],
      items:
          (json['items'] as List)
              .map((item) => OrderItem.fromJson(item))
              .toList(),
      totalPrice: json['total_price'],
      shippingCost: json['shipping_cost'],
      grandTotal: json['grand_total'],
    );
  }
}

class OrderItem {
  final int tenantId;
  final String tenantName;
  final List<ProductItem> items;

  OrderItem({
    required this.tenantId,
    required this.tenantName,
    required this.items,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      tenantId: json['tenant_id'],
      tenantName: json['tenant_name'],
      items:
          (json['items'] as List)
              .map((item) => ProductItem.fromJson(item))
              .toList(),
    );
  }
}

class ProductItem {
  final int productId;
  final String productName;
  final int quantity;
  final int price;
  final int subtotal;

  ProductItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
    required this.subtotal,
  });

  factory ProductItem.fromJson(Map<String, dynamic> json) {
    return ProductItem(
      productId: json['product_id'],
      productName: json['product_name'],
      quantity: json['quantity'],
      price: json['price'],
      subtotal: json['subtotal'],
    );
  }
}

class WorkSummary {
  final int total_orders_handled;
  final int total_income;

  WorkSummary({required this.total_orders_handled, required this.total_income});

  factory WorkSummary.fromJson(Map<String, dynamic> json) {
    return WorkSummary(
      total_orders_handled: json['total_orders_handled'],
      total_income: json['total_income'],
    );
  }
}
