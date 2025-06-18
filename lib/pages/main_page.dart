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

// --- STYLING CONSTANTS ---
const primaryColor = Color(0xFFFF7622);
const secondaryColor = Color(0xFFFFC529);
const backgroundColor = Color(0xFFF8F9FA);
const textColor = Color(0xFF333333);
const greenColor = Color(0xFF28A745);
const redColor = Color(0xFFDC3545);

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
        scaffoldBackgroundColor: backgroundColor,
        useMaterial3: true,
        primaryColor: primaryColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          background: backgroundColor,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: backgroundColor,
          elevation: 0,
          iconTheme: IconThemeData(color: textColor),
        ),
        cardTheme: CardTheme(
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.05),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      home: const MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  List<Order> orders = [];
  bool isLoading = true;
  bool _isToggling = false;
  bool isOnline = false;
  int currentIndex = 0;
  String username = "Porter";

  int orderCount = 0;
  int incomeCount = 0;

  Timer? _timer;

  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _fetchAllData();
    startInterval();
  }

  Future<void> _fetchAllData() async {
    setState(() => isLoading = true);
    await Future.wait([
      checkLoginStatus(),
      loadStatusPorter(),
      loadOrders(),
      loadPorter(),
    ]);
    if (mounted) setState(() => isLoading = false);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void startInterval() {
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (currentIndex == 0 && mounted && !isLoading) {
        loadOrders();
        loadPorter();
      }
    });
  }

  Future<void> loadOrders() async {
    try {
      final result = await OrderService.fetchActiveOrder();
      if (mounted) {
        setState(() => orders = result);
      }
    } catch (e) {
      print('Error fetching orders: $e');
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
    }
  }

  Future<void> loadStatusPorter() async {
    try {
      final result = await PorterService.getPorterOnlineStatus();
      if (mounted) setState(() => isOnline = result.porterIsOnline);
    } catch (e) {
      print('Error fetching porter status: $e');
    }
  }

  Future<void> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('user_name') ?? 'Porter';
    if (mounted) setState(() => username = name);
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

  void _showStyledSnackBar(
    String message, {
    bool isError = false,
    bool isSuccess = false,
  }) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontFamily: 'Sen', color: Colors.white),
        ),
        backgroundColor:
            isError ? redColor : (isSuccess ? greenColor : primaryColor),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Kembali ke struktur awal tanpa BottomNavigationBar
    return Scaffold(
      body: SafeArea(
        child: _buildOrderPage(), // Langsung menampilkan halaman order
      ),
    );
  }

  Widget _buildOrderPage() {
    return RefreshIndicator(
      onRefresh: _fetchAllData,
      color: primaryColor,
      child: ListView(
        // Menggunakan ListView agar bisa scroll
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildHeader(),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildSummary(),
          ),
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Active Orders',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                fontFamily: 'Sen',
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildOrderList(), // Widget ini akan menangani paddingnya sendiri
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment:
          CrossAxisAlignment.center, // Memastikan alignment vertikal
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Hello, $username',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                color: textColor,
                fontFamily: 'Sen',
              ),
            ),
            const SizedBox(height: 2),
            Text(
              isOnline ? 'You are online' : 'You are offline',
              style: TextStyle(
                fontSize: 14,
                color: isOnline ? greenColor : Colors.grey[600],
                fontFamily: 'Sen',
              ),
            ),
          ],
        ),
        Row(
          children: [
            Switch(
              value: isOnline,
              activeColor: greenColor,
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
                          _showStyledSnackBar(
                            val
                                ? 'Status online diaktifkan.'
                                : 'Status online dinonaktifkan.',
                            isSuccess: val,
                          );
                        } else {
                          _showStyledSnackBar(
                            'Gagal mengubah status online.',
                            isError: true,
                          );
                        }
                        setState(() => _isToggling = false);
                      },
            ),
            IconButton(
              icon: const Icon(Icons.logout_outlined, color: textColor),
              onPressed: _logout,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOrderList() {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(color: primaryColor),
        ),
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
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(48.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 80,
                color: Colors.grey[300],
              ),
              const SizedBox(height: 16),
              const Text(
                'No Active Orders',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'New orders will appear here.',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: filteredOrders.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final order = filteredOrders[index];
        return _buildOrderCard(index, order);
      },
    );
  }

  Widget _buildSummary() {
    return Card(
      elevation: 8,
      shadowColor: primaryColor.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [primaryColor, primaryColor.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _summaryBox(
                orderCount.toString(),
                'ORDERS',
                Icons.receipt_long_outlined,
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withOpacity(0.5),
              ),
              _summaryBox(
                currencyFormatter.format(incomeCount),
                'INCOME',
                Icons.account_balance_wallet_outlined,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryBox(String value, String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 36),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOrderCard(int index, Order order) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currencyFormatter.format(order.grandTotal ?? 0),
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: _buildOrderActions(order, index),
            ),
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
            'Decline',
            Colors.white,
            redColor,
            () => _handleDecline(order.orderId, index),
            borderColor: redColor,
          ),
          const SizedBox(width: 8),
          _roundedButton(
            'Accept',
            primaryColor,
            Colors.white,
            () => _handleAccept(order.orderId, index),
          ),
        ];
      case 'received':
        return [
          _roundedButton(
            'Details',
            primaryColor,
            Colors.white,
            () => _showOrderDetailsDialog(index, order),
          ),
        ];
      case 'on-delivery':
        return [
          _roundedButton(
            'Finish',
            greenColor,
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
    // Simple error handling for demonstration.
    _showStyledSnackBar(errorMessage, isError: true);
  }

  Future<void> _handleAccept(int orderId, int index) async {
    try {
      final message = await OrderService.acceptOrder(orderId);
      _showStyledSnackBar(
        message ?? 'Order accepted successfully.',
        isSuccess: true,
      );
      loadOrders();
    } catch (e) {
      _handleError(e, 'Failed to accept order.');
    }
  }

  Future<void> _handleDecline(int orderId, int index) async {
    try {
      final message = await OrderService.rejectOrder(orderId);
      _showStyledSnackBar(message ?? 'Order declined.');
      loadOrders();
    } catch (e) {
      _handleError(e, 'Failed to decline order.');
    }
  }

  Future<void> _handleDeliver(int orderId) async {
    try {
      final message = await OrderService.deliverOrder(orderId);
      _showStyledSnackBar(
        message ?? 'Order is now out for delivery.',
        isSuccess: true,
      );
      loadOrders();
    } catch (e) {
      _handleError(e, 'Failed to start delivery.');
    }
  }

  Future<void> _handleFinish(int orderId) async {
    try {
      final message = await OrderService.finishOrder(orderId);
      _showStyledSnackBar(
        message ?? 'Order finished successfully.',
        isSuccess: true,
      );
      loadOrders();
      loadPorter();
    } catch (e) {
      _handleError(e, 'Failed to finish order.');
    }
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
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          _handleDeliver(order.orderId);
                        },
                        child: const Text(
                          "START DELIVERY",
                          style: TextStyle(fontWeight: FontWeight.bold),
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
          Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
          const Divider(height: 16),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${item['name'] ?? 'Item'} x${item['qty'] ?? 1}',
                    ),
                  ),
                  Text(currencyFormatter.format(item['price'] ?? 0)),
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
              fontSize: isBold ? 16 : 14,
              color: isBold ? Colors.black : Colors.grey.shade700,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 16 : 14,
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
    VoidCallback onPressed, {
    Color? borderColor,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        foregroundColor: textColor,
        elevation: bgColor == Colors.white ? 0 : 2,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side:
              borderColor != null
                  ? BorderSide(color: borderColor)
                  : BorderSide.none,
        ),
        textStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          fontFamily: 'Sen',
        ),
      ),
      child: Text(text),
    );
  }
}
