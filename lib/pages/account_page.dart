import 'package:flutter/material.dart';
import '../services/profile_service.dart';
import '../models/profile.dart';

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
    // Pastikan widget masih ada sebelum memulai async operation
    if (!mounted) return;

    // Set loading state
    setState(() {
      _isLoading = true;
    });

    try {
      final profile = await PorterService.fetchPorterProfile();
      // Periksa lagi setelah async operation selesai
      if (mounted) {
        setState(() {
          _profile = profile;
          _rekeningController.text = profile.accountNumber;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Gagal load profile: $e');
      // Periksa lagi sebelum menampilkan SnackBar atau mengubah state
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Gagal memuat profil')));
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

      // TODO: Implement logic to save the new account number to the server
      // final success = await PorterService.updateAccountNumber(rekening);
      // if (success) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     SnackBar(content: Text('Nomor rekening berhasil disimpan')),
      //   );
      // } else {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     SnackBar(content: Text('Gagal menyimpan nomor rekening')),
      //   );
      // }

      // For now, just show a confirmation message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nomor rekening berhasil disimpan: $rekening')),
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
    const buttonColor = Color(0xFFFF7622);
    const buttonTextStyle = TextStyle(
      fontFamily: 'Sen',
      fontWeight: FontWeight.bold,
      fontSize: 16,
      color: Colors.white,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(30, 22, 30, 0),
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _profile == null
                ? const Center(child: Text('Profil tidak tersedia'))
                : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'My Profile',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Sen',
                      ),
                    ),
                    const SizedBox(height: 30),
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 30,
                          backgroundImage: AssetImage('assets/avatar.png'),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _profile!.porterName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Sen',
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Porter',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                                fontFamily: 'Sen',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    _ProfileItem(label: 'Jurusan', value: _profile!.department),
                    _ProfileItem(label: 'NRP', value: _profile!.porterNrp),

                    // Rekening
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Nomor Rekening',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black,
                                    fontFamily: 'Sen',
                                  ),
                                ),
                                const SizedBox(height: 6),
                                _isEditing
                                    ? TextField(
                                      controller: _rekeningController,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(
                                          vertical: 8,
                                          horizontal: 12,
                                        ),
                                        border: OutlineInputBorder(),
                                      ),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Sen',
                                      ),
                                    )
                                    : Text(
                                      _rekeningController.text,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Sen',
                                      ),
                                    ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: _toggleEditSave,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: buttonColor,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              _isEditing ? 'Save' : 'Edit',
                              style: buttonTextStyle,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(),
                  ],
                ),
      ),
    );
  }
}

class _ProfileItem extends StatelessWidget {
  final String label;
  final String value;

  const _ProfileItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black,
              fontFamily: 'Sen',
            ),
          ),
          subtitle: Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'Sen',
            ),
          ),
        ),
        const Divider(),
      ],
    );
  }
}

class _RatingItem extends StatelessWidget {
  final double rating;
  const _RatingItem({this.rating = 5.0});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text(
            'Rating',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black,
              fontFamily: 'Sen',
            ),
          ),
          subtitle: Row(
            children: [
              const Icon(Icons.star, color: Colors.orange, size: 18),
              const SizedBox(width: 4),
              Text(
                rating.toStringAsFixed(1), // Display actual rating
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Sen',
                ),
              ),
            ],
          ),
        ),
        const Divider(),
      ],
    );
  }
}
