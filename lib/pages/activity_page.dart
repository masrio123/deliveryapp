import 'package:flutter/material.dart';
import 'dart:math';

import 'package:petraporter_deliveryapp/pages/main_page.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: MainPage(), debugShowCheckedModeBanner: false);
  }
}

class ActivityPage extends StatelessWidget {
  final List<String> randomImages = [
    'https://i.pravatar.cc/150?img=3',
    'https://i.pravatar.cc/150?img=7',
    'https://i.pravatar.cc/150?img=12',
    'https://i.pravatar.cc/150?img=18',
    'https://i.pravatar.cc/150?img=25',
  ];

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

            // Kotak 1
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
              ),
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(
                    randomImages[random.nextInt(randomImages.length)],
                  ),
                  radius: 24,
                ),
                title: const Text(
                  'Reyhan',
                  style: TextStyle(fontSize: 18, fontFamily: 'Sen'),
                ),
                subtitle: const Text(
                  'Order ID: 1101',
                  style: TextStyle(fontFamily: 'Sen'),
                ),
                trailing: const Text(
                  'Completed',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Sen',
                  ),
                ),
              ),
            ),

            // Kotak 2
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
              ),
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(
                    randomImages[random.nextInt(randomImages.length)],
                  ),
                  radius: 24,
                ),
                title: const Text(
                  'Ayu',
                  style: TextStyle(fontSize: 18, fontFamily: 'Sen'),
                ),
                subtitle: const Text(
                  'Order ID: 1102',
                  style: TextStyle(fontFamily: 'Sen'),
                ),
                trailing: const Text(
                  'Completed',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Sen',
                  ),
                ),
              ),
            ),

            // Kotak 3
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
              ),
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(
                    randomImages[random.nextInt(randomImages.length)],
                  ),
                  radius: 24,
                ),
                title: const Text(
                  'Budi',
                  style: TextStyle(fontSize: 18, fontFamily: 'Sen'),
                ),
                subtitle: const Text(
                  'Order ID: 1103',
                  style: TextStyle(fontFamily: 'Sen'),
                ),
                trailing: const Text(
                  'Completed',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Sen',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
