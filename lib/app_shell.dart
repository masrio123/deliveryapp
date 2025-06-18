import 'package:flutter/material.dart';

// PENTING: Sesuaikan path di bawah ini dengan struktur folder aplikasi Porter Anda!
import '../pages/main_page.dart';
import '../pages/activity_page.dart';
import '../pages/account_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  // State untuk melacak tab mana yang sedang aktif.
  int _selectedIndex = 0;

  // Daftar semua halaman utama untuk aplikasi Porter.
  static final List<Widget> _widgetOptions = <Widget>[
    MainPage(), // Index 0: Halaman utama berisi daftar tugas
    ActivityPage(), // Index 1: Halaman riwayat tugas yang sudah selesai
    AccountPage(), // Index 2: Halaman profil porter
  ];

  // Fungsi yang akan dipanggil saat salah satu tab ditekan.
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Bagian body akan secara otomatis menampilkan halaman yang sesuai
      // dengan tab yang dipilih (_selectedIndex).
      body: _widgetOptions.elementAt(_selectedIndex),

      // Di sinilah kita mendefinisikan BottomNavigationBar-nya.
      bottomNavigationBar: BottomNavigationBar(
        // Label untuk aplikasi Porter
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Order'),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Activity',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Account'),
        ],
        currentIndex:
            _selectedIndex, // Ini membuat icon yang aktif jadi berwarna.
        onTap: _onItemTapped, // Ini menghubungkan aksi tap dengan fungsi kita.
        selectedItemColor: const Color(0xFFFF7622), // Warna item aktif.
        unselectedItemColor: Colors.grey, // Warna item tidak aktif.
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed, // Agar semua label terlihat.
        // --- PERBAIKAN DI SINI ---
        // Mengatur font untuk label navigasi
        // --- PERUBAHAN DI SINI ---
        // Menambah ukuran ikon dan font agar navbar terlihat lebih besar.
        iconSize: 35, // Ukuran ikon diperbesar (default: 24)
        selectedFontSize: 15, // Ukuran font label yang aktif (default: 14)
        unselectedFontSize:
            13, // Ukuran font label yang tidak aktif (default: 12)
        // Menambah sedikit padding di bawah ikon
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          height: 1.5,
        ),
        unselectedLabelStyle: const TextStyle(height: 1.5),
      ),
    );
  }
}
