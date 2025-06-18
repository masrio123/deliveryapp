import 'package:flutter/material.dart';
import '../services/profile_service.dart';
import '../models/profile.dart';

// --- PERUBAHAN --- Menyamakan konstanta warna dengan halaman Customer
const Color _primaryColor = Color(0xFFFF7622);
const Color _backgroundColor = Color(0xFFFFFFFF);
const Color _textColor = Color(0xFF333333);
const Color _subtleTextColor = Colors.grey;

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  _AccountPageState createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  PorterProfile? _profile;
  bool _isLoading = true;
  bool _isEditing = false;

  final TextEditingController _rekeningController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final profile = await PorterService.fetchPorterProfile();
      if (mounted) {
        setState(() {
          _profile = profile;
          _rekeningController.text = profile.accountNumber;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Gagal load profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Gagal memuat profil.'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _toggleEditSave() {
    if (_isEditing) {
      final rekening = _rekeningController.text.trim();
      if (rekening.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nomor rekening tidak boleh kosong')),
        );
        return;
      }

      // if (mounted && _profile != null) {
      //     setState(() {
      //         _profile!.accountNumber = rekening;
      //     });
      // }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Nomor rekening berhasil disimpan: $rekening'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }

    setState(() {
      _isEditing = !_isEditing;
    });
  }

  @override
  void dispose() {
    _rekeningController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // --- PERUBAHAN --- Mengadopsi struktur Scaffold dari halaman Customer
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text(
          "My Profile",
          style: TextStyle(
            color: _textColor,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        backgroundColor: _backgroundColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _loadProfile,
        color: _primaryColor,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: _primaryColor),
      );
    }

    if (_profile == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.wifi_off_rounded, color: Colors.grey[400], size: 60),
              const SizedBox(height: 16),
              const Text(
                "Gagal memuat data profile.\nSilakan periksa koneksi Anda.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: _subtleTextColor),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                onPressed: _loadProfile,
                icon: const Icon(Icons.refresh),
                label: const Text("Coba Lagi"),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        children: [
          _buildProfileHeader(),
          const SizedBox(height: 32),
          _buildInfoDetails(),
        ],
      ),
    );
  }

  // --- PERUBAHAN --- Widget disesuaikan untuk data Porter
  Widget _buildProfileHeader() {
    return Column(
      children: [
        const CircleAvatar(
          radius: 50,
          backgroundImage: AssetImage('assets/avatar.png'),
          backgroundColor: Colors.black12,
        ),
        const SizedBox(height: 16),
        Text(
          _profile!.porterName,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: _textColor,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        // Menampilkan NRP di bawah nama, mirip identityNumber di Customer
        Text(
          _profile!.porterNrp,
          style: const TextStyle(fontSize: 16, color: _subtleTextColor),
        ),
      ],
    );
  }

  // --- PERUBAHAN --- Widget disesuaikan untuk data Porter dan fungsi edit
  Widget _buildInfoDetails() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Info Jurusan
          _buildInfoRow(
            label: "Jurusan",
            value: _profile!.department,
            icon: Icons.school_outlined,
          ),
          const Divider(height: 1),
          // Info Nomor Rekening yang dapat diedit
          _buildEditableRekeningRow(),
        ],
      ),
    );
  }

  // Widget untuk baris info statis (Jurusan)
  Widget _buildInfoRow({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        children: [
          Icon(icon, color: _primaryColor, size: 24),
          const SizedBox(width: 16),
          Text(label, style: const TextStyle(fontSize: 16, color: _textColor)),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _subtleTextColor,
            ),
          ),
        ],
      ),
    );
  }

  // Widget khusus untuk baris Nomor Rekening yang bisa diedit
  Widget _buildEditableRekeningRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        children: [
          const Icon(
            Icons.account_balance_wallet_outlined,
            color: _primaryColor,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child:
                _isEditing
                    ? TextField(
                      controller: _rekeningController,
                      keyboardType: TextInputType.number,
                      autofocus: true,
                      decoration: const InputDecoration.collapsed(
                        hintText: 'Masukkan nomor rekening',
                      ),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _textColor,
                      ),
                    )
                    : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Nomor Rekening",
                          style: TextStyle(fontSize: 16, color: _textColor),
                        ),
                        Text(
                          _rekeningController.text,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _subtleTextColor,
                          ),
                        ),
                      ],
                    ),
          ),
          TextButton(
            onPressed: _toggleEditSave,
            child: Text(
              _isEditing ? 'Save' : 'Edit',
              style: const TextStyle(
                color: _primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
