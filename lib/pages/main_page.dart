import 'package:flutter/material.dart';
import 'package:petraporter_deliveryapp/pages/account_page.dart';
import 'activity_page.dart';
import '../services/order_service.dart';
import '../models/order.dart';

void main() {
  runApp(MyApp());
}

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
  bool isOnline = true;
  int currentIndex = 1;

  @override
  void initState() {
    super.initState();
    loadOrders();
  }

  Future<void> loadOrders() async {
    try {
      final result = await OrderService.fetchActiveOrder();

      setState(() {
        orders = result;
        orderStatuses = List.generate(result.length, (_) => OrderStatus.none);
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching orders: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },
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
          // Greeting and switch
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Hello, Jovan',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                  fontFamily: 'Sen',
                ),
              ),
              Switch(
                value: isOnline,
                activeColor: Colors.green,
                onChanged: (val) => setState(() => isOnline = val),
              ),
            ],
          ),
          SizedBox(height: 20),
          // Summary
          Container(
            padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _summaryBox('0', 'ORDERS'),
                Container(width: 1, height: 40, color: Colors.grey.shade400),
                _summaryBox('Rp0', 'TOTAL INCOME'),
              ],
            ),
          ),
          SizedBox(height: 30),
          Text(
            'Order Requests',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              fontFamily: 'Sen',
            ),
          ),
          SizedBox(height: 16),
          if (isLoading)
            Center(child: CircularProgressIndicator())
          else if (orders.isEmpty)
            Text('No active orders.')
          else
            Column(
              children: List.generate(orders.length, (index) {
                final order = orders[index];
                return _orderCard(
                  imageUrl: 'https://i.pravatar.cc/100',
                  name: order.customerName,
                  price: 'Rp${order.grandTotal}',
                  status: orderStatuses[index],
                  onAccept: () {
                    setState(() => orderStatuses[index] = OrderStatus.accepted);
                  },
                  onDecline: () {
                    setState(() => orderStatuses[index] = OrderStatus.finished);
                  },
                  onDetails: () {
                    _showOrderDetailsDialog(index);
                  },
                  onFinish: () {
                    setState(() => orderStatuses[index] = OrderStatus.finished);
                  },
                );
              }),
            ),
        ],
      ),
    );
  }

  Widget _summaryBox(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            fontFamily: 'Sen',
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontFamily: 'Sen',
          ),
        ),
      ],
    );
  }

  Widget _orderCard({
    required String imageUrl,
    required String name,
    required String price,
    required OrderStatus status,
    required VoidCallback onAccept,
    required VoidCallback onDecline,
    required VoidCallback onDetails,
    required VoidCallback onFinish,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(backgroundImage: NetworkImage(imageUrl), radius: 26),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    fontFamily: 'Sen',
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  price,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontFamily: 'Sen',
                  ),
                ),
              ],
            ),
          ),
          if (status == OrderStatus.none) ...[
            _roundedButton('Accept', Color(0xFFFF7622), Colors.white, onAccept),
            SizedBox(width: 8),
            _roundedButton('Decline', Colors.red, Colors.white, onDecline),
          ] else if (status == OrderStatus.accepted) ...[
            _roundedButton('Details', Colors.orange, Colors.white, onDetails),
          ] else if (status == OrderStatus.delivering) ...[
            _roundedButton(
              'Finish Order',
              Colors.green,
              Colors.white,
              onFinish,
            ),
          ],
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
        textStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          fontFamily: 'Sen',
        ),
      ),
      child: Text(text),
    );
  }

  void _showOrderDetailsDialog(int index) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text(
              'Order Details',
              style: TextStyle(fontFamily: 'Sen', fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _restaurantCard(
                    name: 'Ndokee Express',
                    items: [
                      {'name': 'Nasi Goreng Ayam', 'qty': 1, 'price': 30000},
                      {
                        'name': 'Nasi Goreng Hongkong',
                        'qty': 1,
                        'price': 30000,
                      },
                    ],
                  ),
                  SizedBox(height: 12),
                  _restaurantCard(
                    name: 'Depot Kita',
                    items: [
                      {'name': 'Mie Goreng', 'qty': 1, 'price': 30000},
                      {'name': 'Nasi Empal', 'qty': 1, 'price': 30000},
                    ],
                    note: 'extra garam sama msg',
                  ),
                  SizedBox(height: 16),
                  Divider(thickness: 1),
                  Text(
                    'Total Payment',
                    style: TextStyle(
                      fontFamily: 'Sen',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  _priceRow('Total Price', 'Rp120.000'),
                  _priceRow('Delivery Fee', 'Rp6.000'),
                  _priceRow('TOTAL', 'Rp126.000', isBold: true),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() => orderStatuses[index] = OrderStatus.delivering);
                },
                child: Text(
                  'DELIVER',
                  style: TextStyle(color: Colors.orange, fontFamily: 'Sen'),
                ),
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
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Sen'),
          ),
          SizedBox(height: 8),
          ...items.map(
            (item) => Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${item['name']} x${item['qty']}',
                  style: TextStyle(fontFamily: 'Sen'),
                ),
                Text('Rp${item['price']}', style: TextStyle(fontFamily: 'Sen')),
              ],
            ),
          ),
          if (note != null) ...[
            SizedBox(height: 6),
            Text(
              'Catatan: $note',
              style: TextStyle(
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
              fontFamily: 'Sen',
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Sen',
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
