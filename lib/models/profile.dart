class PorterProfile {
  final String porterName;
  final String porterNrp;
  final String department;
  // --- PERUBAHAN ---
  final String bankName;
  final String accountNumber;
  final String username; // Ini untuk nama pemilik rekening (A.N)

  PorterProfile({
    required this.porterName,
    required this.porterNrp,
    required this.department,
    // --- PERUBAHAN ---
    required this.bankName,
    required this.accountNumber,
    required this.username,
  });

  factory PorterProfile.fromJson(Map<String, dynamic> json) {
    return PorterProfile(
      porterName: json['porter_name'] ?? 'No Name',
      porterNrp: json['porter_nrp'] ?? 'No NRP',
      department:
          json['department'] ??
          'N/A', // Asumsi nama relasinya 'department' dan fieldnya 'department_name'
      // --- PERUBAHAN ---
      // Sesuaikan key JSON ini dengan response dari API Anda
      bankName: json['bank_name'] ?? 'N/A',
      accountNumber:
          json['account_numbers'] ?? 'N/A', // Sesuaikan key jika berbeda
      username: json['username'] ?? 'N/A',
    );
  }
}

// Model untuk menangani response status online porter
class PorterStatus {
  final bool porterIsOnline;

  PorterStatus({required this.porterIsOnline});

  factory PorterStatus.fromJson(Map<String, dynamic> json) {
    return PorterStatus(porterIsOnline: json['porter_isOnline'] ?? false);
  }
}
