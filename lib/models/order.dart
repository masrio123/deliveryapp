// Helper function untuk parsing angka dengan aman.
// Letakkan ini di bagian atas file model Anda.
int _parseInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.round(); // Mengubah double ke int
  if (value is String)
    return int.tryParse(value) ?? 0; // Mengubah string ke int
  return 0; // Nilai default jika semua gagal
}

int? _parseNullableInt(dynamic value) {
  if (value == null) return null;
  return _parseInt(value);
}

class Order {
  final int orderId;
  final int? cartId;
  final int? customerId;
  final String customerName;
  final int? tenantLocationId;
  final String tenantLocationName;
  final String deliveryPointName;
  final String orderStatus;
  final List<OrderItem> items;
  final int? totalPrice;
  final int? shippingCost;
  final int? grandTotal;

  Order({
    required this.orderId,
    this.cartId,
    this.customerId,
    required this.customerName,
    required this.tenantLocationId,
    required this.deliveryPointName,
    required this.tenantLocationName,
    required this.orderStatus,
    required this.items,
    this.totalPrice,
    this.shippingCost,
    this.grandTotal,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      orderId: _parseInt(json['order_id']),
      cartId: _parseNullableInt(json['cart_id']),
      customerId: _parseNullableInt(json['customer_id']),
      customerName: json['customer_name'] ?? 'Customer Dihapus',
      tenantLocationId: _parseNullableInt(json['tenant_location_id']),
      deliveryPointName:
          json['delivery_point_name'] ?? 'Lokasi Tidak Diketahui',
      tenantLocationName:
          json['tenant_location_name'] ?? 'Lokasi Tidak Ditemukan',
      orderStatus: json['order_status'] ?? 'unknown',
      items:
          (json['items'] as List? ?? [])
              .map((item) => OrderItem.fromJson(item))
              .toList(),
      totalPrice: _parseNullableInt(json['total_price']),
      shippingCost: _parseNullableInt(json['shipping_cost']),
      grandTotal: _parseNullableInt(json['grand_total']),
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
      tenantId: _parseInt(json['tenant_id']),
      tenantName: json['tenant_name'] ?? 'Tenant Dihapus',
      items:
          (json['items'] as List? ?? [])
              .map((item) => ProductItem.fromJson(item))
              .toList(),
    );
  }
}

class ProductItem {
  // final int productId; // Sudah dihapus sesuai permintaan sebelumnya
  final String productName;
  final int quantity;
  final int price;
  final int subtotal;
  final String? notes;

  ProductItem({
    // required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
    required this.subtotal,
    this.notes,
  });

  factory ProductItem.fromJson(Map<String, dynamic> json) {
    return ProductItem(
      // productId: _parseInt(json['product_id']), // Sudah dihapus
      productName: json['product_name'] ?? 'Produk Dihapus',
      quantity: _parseInt(json['quantity']),
      price: _parseInt(json['price']),
      subtotal: _parseInt(json['subtotal']),
      notes: json['notes'],
    );
  }
}

class WorkSummary {
  final int total_orders_handled;
  final int total_income;

  WorkSummary({required this.total_orders_handled, required this.total_income});

  factory WorkSummary.fromJson(Map<String, dynamic> json) {
    return WorkSummary(
      total_orders_handled: _parseInt(json['total_orders_handled']),
      total_income: _parseInt(json['total_income']),
    );
  }
}
