import 'package:flutter/material.dart';
import '../services/profile_service.dart';
import '../models/profile.dart';
import '../models/review.dart';

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
  bool _isSaving = false;

  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _accountNumberController =
      TextEditingController();
  final TextEditingController _usernameController = TextEditingController();

  List<PorterReview> _reviews = [];
  bool _isReviewLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _isReviewLoading = true;
    });

    try {
      final profile = await PorterService.fetchPorterProfile();
      final reviews = await PorterService.fetchPorterReviews();
      if (mounted) {
        setState(() {
          _profile = profile;
          _bankNameController.text = profile.bankName;
          _accountNumberController.text = profile.accountNumber;
          _usernameController.text = profile.username;
          _reviews = reviews;
          _isLoading = false;
          _isReviewLoading = false;
        });
      }
    } catch (e) {
      print('Gagal load profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal memuat profil. Silakan coba lagi.'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() {
          _isLoading = false;
          _isReviewLoading = false;
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    setState(() {
      _isSaving = true;
    });

    final success = await PorterService.updatePorterBankDetails(
      bankName: _bankNameController.text,
      accountNumber: _accountNumberController.text,
      username: _usernameController.text,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Profil bank berhasil diperbarui'
                : 'Gagal memperbarui profil',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() {
        _isEditing = false;
        _isSaving = false;
      });
      if (success) _loadProfile();
    }
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  @override
  void dispose() {
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      children: [
        _buildProfileHeader(),
        const SizedBox(height: 32),
        _buildInfoDetails(),
        const SizedBox(height: 16),

        // Tombol Edit Bank (diletakkan sebelum review)
        if (_isSaving)
          const Center(child: CircularProgressIndicator(color: _primaryColor)),
        if (!_isSaving)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _isEditing ? Colors.green : _primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: _isEditing ? _saveProfile : _toggleEdit,
              child: Text(
                _isEditing ? 'Simpan Perubahan' : 'Edit Detail Bank',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        if (_isEditing)
          TextButton(onPressed: _toggleEdit, child: const Text("Batal")),

        const SizedBox(height: 32),
        _buildReviewSection(),
      ],
    );
  }

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
        Text(
          _profile!.porterNrp,
          style: const TextStyle(fontSize: 16, color: _subtleTextColor),
        ),
      ],
    );
  }

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
          _buildInfoRow(
            label: "Jurusan",
            value: _profile!.department,
            icon: Icons.school_outlined,
          ),
          const Divider(height: 1),
          _buildBankInfoRow(
            label: "Nama Bank",
            controller: _bankNameController,
            icon: Icons.business_outlined,
          ),
          const Divider(height: 1),
          _buildBankInfoRow(
            label: "Atas Nama",
            controller: _usernameController,
            icon: Icons.person_outline_rounded,
          ),
          const Divider(height: 1),
          _buildBankInfoRow(
            label: "No. Rekening",
            controller: _accountNumberController,
            icon: Icons.credit_card_outlined,
            isNumeric: true,
          ),
        ],
      ),
    );
  }

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

  Widget _buildBankInfoRow({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool isNumeric = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: _primaryColor, size: 24),
          const SizedBox(width: 16),
          Text(label, style: const TextStyle(fontSize: 16, color: _textColor)),
          const Spacer(),
          Expanded(
            child:
                _isEditing
                    ? TextField(
                      controller: controller,
                      textAlign: TextAlign.end,
                      keyboardType:
                          isNumeric ? TextInputType.number : TextInputType.text,
                      decoration: const InputDecoration.collapsed(
                        hintText: '...',
                      ),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _textColor,
                      ),
                    )
                    : Text(
                      controller.text,
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _subtleTextColor,
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewSection() {
    if (_isReviewLoading) {
      return const Center(
        child: CircularProgressIndicator(color: _primaryColor),
      );
    }
    if (_reviews.isEmpty) {
      return const Center(
        child: Text(
          'Belum ada review dari customer.',
          style: TextStyle(color: _subtleTextColor),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Review dari Customer",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: _textColor,
          ),
        ),
        const SizedBox(height: 16),
        ..._reviews.map(
          (review) => Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        review.rating.toString(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        review.customerName,
                        style: const TextStyle(
                          color: _subtleTextColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(review.review, style: const TextStyle(fontSize: 15)),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Text(
                      review.createdAt,
                      style: const TextStyle(
                        fontSize: 12,
                        color: _subtleTextColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
