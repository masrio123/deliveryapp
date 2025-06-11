import 'package:flutter/material.dart';
import '../services/profile_service.dart';
import '../models/profile.dart';

class AccountPage extends StatefulWidget {
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
    try {
      final profile = await PorterService.fetchPorterProfile();
      setState(() {
        _profile = profile;
        _rekeningController.text = profile.accountNumber;
        _isLoading = false;
      });
    } catch (e) {
      print('Gagal load profile: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal memuat profil')));
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _toggleEditSave() {
    if (_isEditing) {
      final rekening = _rekeningController.text.trim();
      if (rekening.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Nomor rekening tidak boleh kosong')),
        );
        return;
      }

      // Simpan ke server (opsional)
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
                          backgroundImage: NetworkImage(
                            'https://i.pravatar.cc/150?img=18',
                          ),
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
                    _RatingItem(),

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
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            'Rating',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black,
              fontFamily: 'Sen',
            ),
          ),
          subtitle: Row(
            children: [
              Icon(Icons.star, color: Colors.orange, size: 18),
              SizedBox(width: 4),
              Text(
                '5.0',
                style: TextStyle(
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
