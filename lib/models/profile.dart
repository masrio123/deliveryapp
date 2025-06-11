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

  factory PorterProfile.fromJson(Map<String, dynamic> json) {
    return PorterProfile(
      porterName: json['porter_name'],
      porterNrp: json['porter_nrp'],
      department: json['department'],
      accountNumber: json['account_number'],
    );
  }
}

class PorterStatus {
  final bool porterIsOnline;

  PorterStatus({required this.porterIsOnline});

  factory PorterStatus.fromJson(Map<String, dynamic> json) {
    return PorterStatus(porterIsOnline: json['porter_isOnline']);
  }
}
