class PorterProfile {
  final String porterName;
  final String porterNrp;
  final String department;
  final String accountNumber;

  PorterProfile({
    required this.porterName,
    required this.porterNrp,
    required this.department,
    required this.accountNumber,
  });

  // Factory constructor ini akan membuat object dari JSON
  factory PorterProfile.fromJson(Map<String, dynamic> json) {
    return PorterProfile(
      // Menggunakan '??' untuk memberi nilai default jika data null
      porterName: json['porter_name'] ?? 'No Name',
      porterNrp: json['porter_nrp'] ?? 'No NRP',
      department: json['department'] ?? 'N/A',
      accountNumber: json['account_number'] ?? 'N/A',
    );
  }
}

// --- KELAS BARU DITAMBAHKAN DI SINI ---
// Model untuk menangani response status online porter
class PorterStatus {
  final bool porterIsOnline;

  PorterStatus({required this.porterIsOnline});

  factory PorterStatus.fromJson(Map<String, dynamic> json) {
    return PorterStatus(porterIsOnline: json['porter_isOnline'] ?? false);
  }
}
