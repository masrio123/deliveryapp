import 'package:flutter/material.dart';
import 'dart:math';
import 'package:petraporter_deliveryapp/pages/main_page.dart';
import '../services/order_service.dart';
import '../models/order.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: MainPage(), debugShowCheckedModeBanner: false);
  }
}

class ActivityPage extends StatefulWidget {
  @override
  _ActivityPageState createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> {
  final List<String> randomImages = [
    'https://i.pravatar.cc/150?img=3',
    'https://i.pravatar.cc/150?img=7',
    'https://i.pravatar.cc/150?img=12',
    'https://i.pravatar.cc/150?img=18',
    'https://i.pravatar.cc/150?img=25',
  ];

  List<Order> orders = [];
  List<OrderStatus> orderStatuses = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadOrders();
  }

  Future<void> loadOrders() async {
    try {
      final result = await OrderService.fetchActivity();
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

  @override
  Widget build(BuildContext context) {
    final random = Random();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(30, 22, 30, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Activity',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                fontFamily: 'Sen',
              ),
            ),
            const SizedBox(height: 20),
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : Expanded(
                  child: ListView.builder(
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundImage: NetworkImage(
                              randomImages[random.nextInt(randomImages.length)],
                            ),
                            radius: 24,
                          ),
                          title: Text(
                            order.customerName ?? 'Unknown',
                            style: const TextStyle(
                              fontSize: 18,
                              fontFamily: 'Sen',
                            ),
                          ),
                          subtitle: Text(
                            'Order ID: ${order.orderId}',
                            style: const TextStyle(fontFamily: 'Sen'),
                          ),
                          trailing: Text(
                            order.orderStatus ?? 'Unknown',
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Sen',
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
