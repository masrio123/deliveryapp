import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Sesuaikan path import dengan struktur folder Anda
import 'package:petraporter_deliveryapp/pages/account_page.dart';
import 'package:petraporter_deliveryapp/pages/activity_page.dart';
import 'package:petraporter_deliveryapp/services/order_service.dart';
import 'package:petraporter_deliveryapp/models/order.dart';
import 'package:petraporter_deliveryapp/services/profile_service.dart';
import 'package:petraporter_deliveryapp/login/login.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Porter App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Sen',
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
      ),
      home: const MainPage(),
    );
  }
}

enum OrderStatus { none, accepted, delivering, finished }

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  List<Order> orders = [];
  List<OrderStatus> orderStatuses = [];
  bool isLoading = true;
  bool _isToggling = false;
  bool isOnline = false;
  int currentIndex = 0;
  String username = "";

  int orderCount = 0;
  int incomeCount = 0;

  Timer? _timer;

  // Formatter untuk mata uang Rupiah
  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    checkLoginStatus();
    loadStatusPorter();
    loadOrders();
    loadPorter();
    startInterval();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void startInterval() {
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (currentIndex == 0 && mounted) {
        print("Memuat ulang daftar order...");
        loadOrders();
      }
    });
  }

  Future<void> loadOrders() async {
    try {
      final result = await OrderService.fetchActiveOrder();
      if (mounted) {
        setState(() {
          orders = result;
          orderStatuses = List.generate(result.length, (_) => OrderStatus.none);
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching orders: $e');
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> loadPorter() async {
    try {
      final result = await OrderService.fetchWorkSummary();
      if (mounted) {
        setState(() {
          orderCount = result.total_orders_handled;
          incomeCount = result.total_income;
        });
      }
    } catch (e) {
      print('Error fetching porter summary: $e');
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> loadStatusPorter() async {
    try {
      final result = await PorterService.getPorterOnlineStatus();
      if (mounted) {
        setState(() {
          isOnline = result.porterIsOnline;
        });
      }
    } catch (e) {
      print('Error fetching porter status: $e');
      if (mounted) setState(() => isLoading = false);
    }
  }

  void checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('user_name') ?? 'lorem';
    if (mounted) {
      setState(() {
        username = name;
      });
    }
  }

  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: currentIndex,
          children: [_buildOrderPage(), ActivityPage(), const AccountPage()],
        ),
      ),
    );
  }

  Widget _buildOrderPage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 10, right: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.black),
                  onPressed: _logout,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Hello, $username',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 25,
                  fontFamily: 'Sen',
                ),
              ),
              Switch(
                value: isOnline,
                activeColor: Colors.green,
                onChanged:
                    _isToggling
                        ? null
                        : (val) async {
                          setState(() => _isToggling = true);
                          final success =
                              await PorterService.updatePorterOnlineStatus(val);
                          if (!mounted) return;
                          if (success) {
                            setState(() => isOnline = val);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  val
                                      ? 'Status online diaktifkan.'
                                      : 'Status online dinonaktifkan.',
                                ),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Gagal mengubah status online.'),
                              ),
                            );
                          }
                          setState(() => _isToggling = false);
                        },
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildSummary(),
          const SizedBox(height: 24),
          const Text(
            'Active Orders',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 17,
              fontFamily: 'Sen',
            ),
          ),
          const SizedBox(height: 16),
          Expanded(child: _buildOrderList()),
        ],
      ),
    );
  }

  Widget _buildOrderList() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (orders.isEmpty) {
      return const Center(
        child: Text('No active orders.', style: TextStyle(fontFamily: 'Sen')),
      );
    }

    final filteredOrders =
        orders
            .where(
              (order) =>
                  order.orderStatus != 'canceled' &&
                  order.orderStatus != 'finished',
            )
            .toList();

    if (filteredOrders.isEmpty) {
      return const Center(
        child: Text(
          'No new order requests.',
          style: TextStyle(fontFamily: 'Sen'),
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredOrders.length,
      itemBuilder: (context, index) {
        final order = filteredOrders[index];
        return _buildOrderCard(index, order);
      },
    );
  }

  Widget _buildSummary() {
    return Card(
      elevation: 4,
      color: const Color.fromARGB(209, 255, 94, 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _summaryBox(orderCount.toString(), 'ORDERS'),
            Container(
              width: 1,
              height: 40,
              color: const Color.fromARGB(255, 255, 255, 255),
            ),
            _summaryBox(currencyFormatter.format(incomeCount), 'TOTAL INCOME'),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(int index, Order order) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 26,
              backgroundImage: AssetImage('assets/avatar.png'),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.customerName ?? 'Unknown Customer',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      fontFamily: 'Sen',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currencyFormatter.format(order.totalPrice ?? 0),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontFamily: 'Sen',
                    ),
                  ),
                ],
              ),
            ),
            ..._buildOrderActions(order, index),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildOrderActions(Order order, int index) {
    final status = order.orderStatus ?? 'unknown';
    switch (status) {
      case 'waiting':
        return [
          _roundedButton(
            'Accept',
            const Color(0xFFFF7622),
            Colors.white,
            () => _handleAccept(order.orderId, index),
          ),
          const SizedBox(width: 8),
          _roundedButton(
            'Decline',
            Colors.red,
            Colors.white,
            () => _handleDecline(order.orderId, index),
          ),
        ];
      case 'received':
        return [
          _roundedButton(
            'Details',
            const Color(0xFFFF7622),
            Colors.white,
            () => _showOrderDetailsDialog(index, order),
          ),
        ];
      case 'on-delivery':
        return [
          _roundedButton(
            'Finish',
            Colors.green,
            Colors.white,
            () => _handleFinish(order.orderId),
          ),
        ];
      default:
        return [const SizedBox.shrink()];
    }
  }

  void _handleError(dynamic e, String defaultMessage) {
    String errorMessage = defaultMessage;
    String errorString = e.toString();
    if (errorString.contains('{') && errorString.contains('}')) {
      final jsonStartIndex = errorString.indexOf('{');
      try {
        final jsonString = errorString.substring(jsonStartIndex);
        final jsonResponse = json.decode(jsonString);
        if (jsonResponse['message'] != null) {
          errorMessage = jsonResponse['message'];
        }
      } catch (jsonError) {
        print("Failed to parse error JSON: $jsonError");
        errorMessage = 'An unexpected error occurred.';
      }
    }
    _showErrorSnackBar(errorMessage);
  }

  Future<void> _handleAccept(int orderId, int index) async {
    try {
      final message = await OrderService.acceptOrder(orderId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message ?? 'Order accepted successfully.',
            style: const TextStyle(fontFamily: 'Sen'),
          ),
          backgroundColor: Colors.green,
        ),
      );
      loadOrders();
    } catch (e) {
      _handleError(e, 'Failed to accept order.');
    }
  }

  Future<void> _handleDecline(int orderId, int index) async {
    try {
      final message = await OrderService.rejectOrder(orderId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message ?? 'Order declined.',
            style: const TextStyle(fontFamily: 'Sen'),
          ),
          backgroundColor: Colors.orange,
        ),
      );
      loadOrders();
    } catch (e) {
      _handleError(e, 'Failed to decline order.');
    }
  }

  Future<void> _handleDeliver(int orderId) async {
    try {
      final message = await OrderService.deliverOrder(orderId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message ?? 'Order is now out for delivery.',
            style: const TextStyle(fontFamily: 'Sen'),
          ),
          backgroundColor: Colors.green,
        ),
      );
      loadOrders();
    } catch (e) {
      _handleError(e, 'Failed to start delivery.');
    }
  }

  Future<void> _handleFinish(int orderId) async {
    try {
      final message = await OrderService.finishOrder(orderId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message ?? 'Order finished successfully.',
            style: const TextStyle(fontFamily: 'Sen'),
          ),
          backgroundColor: Colors.green,
        ),
      );
      loadOrders();
      loadPorter();
    } catch (e) {
      _handleError(e, 'Failed to finish order.');
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Sen')),
        backgroundColor: Colors.red,
      ),
    );
  }

  Widget _summaryBox(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            fontFamily: 'Sen',
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[300],
            fontFamily: 'Sen',
          ),
        ),
      ],
    );
  }

  void _showOrderDetailsDialog(int index, Order order) {
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
                      order.customerName ?? 'N/A',
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      Icons.location_on_outlined,
                      "DELIVER TO",
                      order.tenantLocationName ?? 'N/A',
                    ),
                    const Divider(height: 32, thickness: 1),
                    Text(
                      "Items to Pick Up",
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
                              order.items.map((item) {
                                return _restaurantCard(
                                  name: item.tenantName ?? 'Unknown Tenant',
                                  items:
                                      item.items
                                          .map(
                                            (p) => {
                                              'name':
                                                  p.productName ??
                                                  'Unknown Item',
                                              'qty': p.quantity ?? 1,
                                              'price': p.price ?? 0,
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
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF7622),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: const TextStyle(
                            fontFamily: 'Sen',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          _handleDeliver(order.orderId);
                        },
                        child: const Text("START DELIVERY"),
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
    String? note,
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
              padding: const EdgeInsets.symmetric(vertical: 2.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${item['name'] ?? 'Item'} x${item['qty'] ?? 1}',
                    style: const TextStyle(fontFamily: 'Sen'),
                  ),
                  Text(
                    currencyFormatter.format(item['price'] ?? 0),
                    style: const TextStyle(fontFamily: 'Sen'),
                  ),
                ],
              ),
            ),
          ),
          if (note != null) ...[
            const SizedBox(height: 6),
            Text(
              'Catatan: $note',
              style: const TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                fontFamily: 'Sen',
              ),
            ),
          ],
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

  Widget _roundedButton(
    String text,
    Color bgColor,
    Color textColor,
    VoidCallback onPressed,
  ) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        foregroundColor: textColor,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          fontFamily: 'Sen',
        ),
      ),
      child: Text(text),
    );
  }
}
