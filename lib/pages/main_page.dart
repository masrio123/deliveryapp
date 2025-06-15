import 'package:flutter/material.dart';
import 'package:petraporter_deliveryapp/pages/account_page.dart';
import 'activity_page.dart';
import '../services/order_service.dart';
import '../models/order.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/profile_service.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:petraporter_deliveryapp/login/login.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
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
      home: MainPage(),
    );
  }
}

enum OrderStatus { none, accepted, delivering, finished }

class MainPage extends StatefulWidget {
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

  @override
  void initState() {
    super.initState();
    checkLoginStatus();
    loadStatusPorter();
    loadOrders();
    loadPorter();
    startInterval();
  }

  Timer? _timer;

  void startInterval() {
    _timer = Timer.periodic(Duration(seconds: 10), (timer) {
      print("order di reload");
      loadOrders();
    });
  }

  Future<void> loadOrders() async {
    try {
      isLoading = true;
      final result = await OrderService.fetchActiveOrder();
      setState(() {
        orders = result;
        orderStatuses = List.generate(result.length, (_) => OrderStatus.none);
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching orders: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> loadPorter() async {
    try {
      final result = await OrderService.fetchWorkSummary();
      setState(() {
        orderCount = result.total_orders_handled;
        incomeCount = result.total_income;
      });
    } catch (e) {
      print('Error fetching orders: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> loadStatusPorter() async {
    try {
      final result = await PorterService.getPorterOnlineStatus();
      setState(() {
        isOnline = result.porterIsOnline;
      });
    } catch (e) {
      print('Error fetching orders: $e');
      setState(() => isLoading = false);
    }
  }

  void checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('user_name') ?? 'lorem';
    setState(() {
      username = name;
    });
  }

  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!mounted) return; // Pastikan widget masih hidup

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) => setState(() => currentIndex = index),
        selectedItemColor: Color(0xFFFF7622),
        unselectedItemColor: Colors.grey[600],
        selectedLabelStyle: TextStyle(fontFamily: 'Sen'),
        unselectedLabelStyle: TextStyle(fontFamily: 'Sen'),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.local_shipping),
            label: 'Order',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.article), label: 'Activity'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Account'),
        ],
      ),
      body: SafeArea(
        child: IndexedStack(
          index: currentIndex,
          children: [_buildOrderPage(), ActivityPage(), AccountPage()],
        ),
      ),
    );
  }

  Widget _buildOrderPage() {
    return SingleChildScrollView(
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
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
              ),
              Switch(
                value: isOnline,
                activeColor: Colors.green,
                onChanged:
                    _isToggling
                        ? null // Disable sementara jika sedang update
                        : (val) async {
                          setState(() {
                            _isToggling = true;
                          });

                          final success =
                              await PorterService.updatePorterOnlineStatus(val);

                          if (success) {
                            setState(() {
                              isOnline = val;
                              _isToggling = false;
                            });
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
                            setState(() {
                              _isToggling = false;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Gagal mengubah status online.'),
                              ),
                            );
                          }
                        },
              ),
            ],
          ),
          SizedBox(height: 20),
          _buildSummary(),
          SizedBox(height: 30),
          Text(
            'Order Requests',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          SizedBox(height: 16),
          if (isLoading)
            Center(child: CircularProgressIndicator())
          else if (orders.isEmpty)
            Text('No active orders.')
          else
            ...orders
                .asMap()
                .entries
                .where(
                  (entry) =>
                      entry.value.orderStatus != 'canceled' ||
                      entry.value.orderStatus != 'received',
                )
                .map((entry) => _buildOrderCard(entry.key, entry.value))
                .toList(),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _summaryBox(orderCount.toString(), 'ORDERS'),
          Container(width: 1, height: 40, color: Colors.grey.shade400),
          _summaryBox(incomeCount.toString(), 'TOTAL INCOME'),
        ],
      ),
    );
  }

  Widget _buildOrderCard(int index, Order order) {
    return Container(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundImage: NetworkImage('https://i.pravatar.cc/100'),
            radius: 26,
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.customerName ?? 'Unknown Customer',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                SizedBox(height: 4),
                Text(
                  'Rp${order.totalPrice ?? 0}',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          ..._buildOrderActions(order, index),
        ],
      ),
    );
  }

  List<Widget> _buildOrderActions(Order order, int index) {
    print("order status item => " + order.orderStatus);
    switch (order.orderStatus) {
      case 'waiting':
        return [
          _roundedButton(
            'Accept',
            Color(0xFFFF7622),
            Colors.white,
            () => _handleAccept(order.orderId, index),
          ),
          SizedBox(width: 8),
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
            Colors.orange,
            Colors.white,
            () => _showOrderDetailsDialog(index, order),
          ),
        ];
      case 'on-delivery':
        return [
          _roundedButton(
            'Finish Order',
            Colors.green,
            Colors.white,
            () => _handleFinish(order.orderId),
          ),
        ];
      default:
        return [];
    }
  }

  Future<void> _handleAccept(int orderId, int index) async {
    try {
      final message = await OrderService.acceptOrder(orderId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.green),
      );
      setState(() => orderStatuses[index] = OrderStatus.accepted);
      loadOrders();
    } catch (e) {
      _showErrorSnackBar('Error accepting order: $e');
    }
  }

  Future<void> _handleDecline(int orderId, int index) async {
    try {
      final message = await OrderService.rejectOrder(orderId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.orange),
      );
      setState(() => orderStatuses[index] = OrderStatus.finished);
      loadOrders();
    } catch (e) {
      _showErrorSnackBar('Error declining order: $e');
    }
  }

  Future<void> _handleDeliver(int orderId) async {
    try {
      final message = await OrderService.deliverOrder(orderId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.green),
      );
      loadOrders();
    } catch (e) {
      _showErrorSnackBar('Error deliver: $e');
    }
  }

  Future<void> _handleFinish(int orderId) async {
    try {
      final message = await OrderService.finishOrder(orderId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.green),
      );
      loadOrders();
      loadPorter();
    } catch (e) {
      _showErrorSnackBar('Error deliver: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Widget _summaryBox(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  void _showOrderDetailsDialog(int index, Order order) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text(
              'Order Details',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...order.items.map(
                    (item) => _restaurantCard(
                      name: item.tenantName,
                      items:
                          item.items
                              .map(
                                (p) => {
                                  'name': p.productName,
                                  'qty': p.quantity,
                                  'price': p.price,
                                },
                              )
                              .toList(),
                    ),
                  ),
                  SizedBox(height: 16),
                  Divider(thickness: 1),
                  Text(
                    'Total Payment',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  _priceRow('Total Price', 'Rp${order.totalPrice}'),
                  _priceRow('Delivery Fee', 'Rp${order.shippingCost}'),
                  _priceRow('TOTAL', 'Rp${order.grandTotal}', isBold: true),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  _handleDeliver(order.orderId);
                  Navigator.pop(context);
                  setState(() => orderStatuses[index] = OrderStatus.delivering);
                },
                child: Text('DELIVER', style: TextStyle(color: Colors.orange)),
              ),
            ],
          ),
    );
  }

  Widget _restaurantCard({
    required String name,
    required List<Map<String, dynamic>> items,
    String? note,
  }) {
    return Container(
      padding: EdgeInsets.all(12),
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          ...items.map(
            (item) => Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${item['name']} x${item['qty']}'),
                Text('Rp${item['price']}'),
              ],
            ),
          ),
          if (note != null) ...[
            SizedBox(height: 6),
            Text(
              'Catatan: $note',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
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
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
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
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
      child: Text(text),
    );
  }
}
