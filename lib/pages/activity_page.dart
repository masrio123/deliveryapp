import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Sesuaikan path import dengan struktur folder Anda
import 'package:petraporter_deliveryapp/services/order_service.dart';
import 'package:petraporter_deliveryapp/models/order.dart';

class ActivityPage extends StatefulWidget {
  const ActivityPage({super.key});

  @override
  State<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> {
  bool isLoading = true;
  List<Order> orders = [];

  // Formatter untuk mata uang Rupiah
  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _refreshActivities();
  }

  Future<void> _refreshActivities() async {
    if (mounted) {
      setState(() => isLoading = true);
    }
    try {
      // Menggunakan fetchActivity yang seharusnya mengambil semua order (termasuk finished/canceled)
      final result = await OrderService.fetchActivity();

      // --- PERUBAHAN: Mengurutkan daftar pesanan berdasarkan orderId ---
      // Pesanan diurutkan berdasarkan ID, yang terbesar akan muncul di paling atas.
      result.sort((a, b) => b.orderId.compareTo(a.orderId));

      if (mounted) {
        setState(() {
          orders = result;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching activity: $e');
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load activity: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshActivities,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Text(
                  'Activity',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Sen',
                  ),
                ),
              ),
              Expanded(
                child:
                    isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : orders.isEmpty
                        ? const Center(
                          child: Text(
                            'No past activities found.',
                            style: TextStyle(fontFamily: 'Sen', fontSize: 16),
                          ),
                        )
                        : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: orders.length,
                          itemBuilder: (context, index) {
                            final order = orders[index];
                            return _buildActivityCard(order);
                          },
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityCard(Order order) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          vertical: 10,
          horizontal: 16,
        ),
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(order.orderStatus).withOpacity(0.1),
          child: Icon(
            _getStatusIcon(order.orderStatus),
            color: _getStatusColor(order.orderStatus),
          ),
        ),
        title: Text(
          order.customerName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Sen',
          ),
        ),
        subtitle: Text(
          'Order ID: #${order.orderId}',
          style: const TextStyle(fontFamily: 'Sen', color: Colors.grey),
        ),
        trailing: ElevatedButton(
          onPressed: () => _showOrderDetailsDialog(context, order),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey.shade200,
            foregroundColor: Colors.black87,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Details', style: TextStyle(fontFamily: 'Sen')),
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'Finished':
        return Colors.green;
      case 'Canceled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String? status) {
    switch (status) {
      case 'Finished':
        return Icons.check_circle_outline;
      case 'Canceled':
        return Icons.cancel_outlined;
      default:
        return Icons.history;
    }
  }

  void _showOrderDetailsDialog(BuildContext context, Order order) {
    showDialog(
      context: context,
      builder:
          (_) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            insetPadding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Order Details",
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "Order ID: #${order.orderId}",
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                    ),
                    const Divider(height: 32, thickness: 1),
                    _buildInfoRow(
                      Icons.person_outline,
                      "CUSTOMER",
                      order.customerName,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      Icons.location_on_outlined,
                      "DELIVERED TO",
                      order.deliveryPointName,
                    ),
                    const Divider(height: 32, thickness: 1),
                    Text(
                      "Items",
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children:
                              order.items.map((orderItem) {
                                return _restaurantCard(
                                  name: orderItem.tenantName,
                                  items:
                                      orderItem.items
                                          .map(
                                            (p) => {
                                              'name': p.productName,
                                              'qty': p.quantity,
                                              'price': p.price,
                                              'notes': p.notes,
                                            },
                                          )
                                          .toList(),
                                );
                              }).toList(),
                        ),
                      ),
                    ),
                    const Divider(height: 32, thickness: 1),
                    _priceRow(
                      'Total Price',
                      currencyFormatter.format(order.totalPrice ?? 0),
                    ),
                    const SizedBox(height: 4),
                    _priceRow(
                      'Delivery Fee',
                      currencyFormatter.format(order.shippingCost ?? 0),
                    ),
                    const SizedBox(height: 8),
                    _priceRow(
                      'TOTAL',
                      currencyFormatter.format(order.grandTotal ?? 0),
                      isBold: true,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text(
                          'Close',
                          style: TextStyle(fontFamily: 'Sen'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.grey.shade700, size: 20),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _restaurantCard({
    required String name,
    required List<Map<String, dynamic>> items,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: 'Sen',
            ),
          ),
          const Divider(height: 16),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${item['name'] ?? 'Item'} x${item['qty'] ?? 1}',
                          style: const TextStyle(fontFamily: 'Sen'),
                        ),
                      ),
                      Text(
                        currencyFormatter.format(item['price'] ?? 0),
                        style: const TextStyle(fontFamily: 'Sen'),
                      ),
                    ],
                  ),
                  if (item['notes'] != null && item['notes'].isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, left: 16),
                      child: Text(
                        'Catatan: "${item['notes']}"',
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey.shade700,
                          fontFamily: 'Sen',
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _priceRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontFamily: 'Sen',
              fontSize: isBold ? 16 : 14,
              color: isBold ? Colors.black : Colors.grey.shade700,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 16 : 14,
              fontFamily: 'Sen',
            ),
          ),
        ],
      ),
    );
  }
}
