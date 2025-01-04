class Authorization {
  final String? authorizationCode;
  final String? bin;
  final String? last4;
  final String? channel;
  final String? cardType;
  final String? bank;
  final String? countryCode;
  final String? brand;
  final String? accountName;
  final String? mobileMoneyNumber;

  Authorization({
    this.authorizationCode,
    this.bin,
    this.last4,
    this.channel,
    this.cardType,
    this.bank,
    this.countryCode,
    this.brand,
    this.accountName,
    this.mobileMoneyNumber,
  });

  factory Authorization.fromJson(Map<String, dynamic> json) {
    return Authorization(
      authorizationCode: json['authorization_code']?.toString(),
      bin: json['bin']?.toString(),
      last4: json['last4']?.toString(),
      channel: json['channel']?.toString(),
      cardType: json['card_type']?.toString(),
      bank: json['bank']?.toString(),
      countryCode: json['country_code']?.toString(),
      brand: json['brand']?.toString(),
      accountName: json['account_name']?.toString(),
      mobileMoneyNumber: json['mobile_money_number']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'authorization_code': authorizationCode,
      'bin': bin,
      'last4': last4,
      'channel': channel,
      'card_type': cardType,
      'bank': bank,
      'country_code': countryCode,
      'brand': brand,
      'account_name': accountName,
      'mobile_money_number': mobileMoneyNumber,
    };
  }
}
