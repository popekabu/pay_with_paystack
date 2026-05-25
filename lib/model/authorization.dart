/// Represents the payment authorization details returned by Paystack after a
/// successful transaction.
class Authorization {
  final String? authorizationCode;
  final String? bin;
  final String? last4;
  final String? expMonth;
  final String? expYear;
  final String? channel;
  final String? cardType;
  final String? bank;
  final String? countryCode;
  final String? brand;
  final bool? reusable;
  final String? signature;
  final String? accountName;
  final String? mobileMoneyNumber;

  const Authorization({
    this.authorizationCode,
    this.bin,
    this.last4,
    this.expMonth,
    this.expYear,
    this.channel,
    this.cardType,
    this.bank,
    this.countryCode,
    this.brand,
    this.reusable,
    this.signature,
    this.accountName,
    this.mobileMoneyNumber,
  });

  factory Authorization.fromJson(Map<String, dynamic> json) {
    return Authorization(
      authorizationCode: json['authorization_code']?.toString(),
      bin: json['bin']?.toString(),
      last4: json['last4']?.toString(),
      expMonth: json['exp_month']?.toString(),
      expYear: json['exp_year']?.toString(),
      channel: json['channel']?.toString(),
      cardType: json['card_type']?.toString(),
      bank: json['bank']?.toString(),
      countryCode: json['country_code']?.toString(),
      brand: json['brand']?.toString(),
      reusable: json['reusable'] is bool
          ? json['reusable']
          : json['reusable']?.toString() == 'true',
      signature: json['signature']?.toString(),
      accountName: json['account_name']?.toString(),
      mobileMoneyNumber: json['mobile_money_number']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'authorization_code': authorizationCode,
      'bin': bin,
      'last4': last4,
      'exp_month': expMonth,
      'exp_year': expYear,
      'channel': channel,
      'card_type': cardType,
      'bank': bank,
      'country_code': countryCode,
      'brand': brand,
      'reusable': reusable,
      'signature': signature,
      'account_name': accountName,
      'mobile_money_number': mobileMoneyNumber,
    };
  }

  /// Returns a copy of this [Authorization] with the specified fields replaced.
  Authorization copyWith({
    String? authorizationCode,
    String? bin,
    String? last4,
    String? expMonth,
    String? expYear,
    String? channel,
    String? cardType,
    String? bank,
    String? countryCode,
    String? brand,
    bool? reusable,
    String? signature,
    String? accountName,
    String? mobileMoneyNumber,
  }) {
    return Authorization(
      authorizationCode: authorizationCode ?? this.authorizationCode,
      bin: bin ?? this.bin,
      last4: last4 ?? this.last4,
      expMonth: expMonth ?? this.expMonth,
      expYear: expYear ?? this.expYear,
      channel: channel ?? this.channel,
      cardType: cardType ?? this.cardType,
      bank: bank ?? this.bank,
      countryCode: countryCode ?? this.countryCode,
      brand: brand ?? this.brand,
      reusable: reusable ?? this.reusable,
      signature: signature ?? this.signature,
      accountName: accountName ?? this.accountName,
      mobileMoneyNumber: mobileMoneyNumber ?? this.mobileMoneyNumber,
    );
  }

  @override
  String toString() {
    return 'Authorization('
        'authorizationCode: $authorizationCode, '
        'bin: $bin, '
        'last4: $last4, '
        'expMonth: $expMonth, '
        'expYear: $expYear, '
        'channel: $channel, '
        'cardType: $cardType, '
        'bank: $bank, '
        'countryCode: $countryCode, '
        'brand: $brand, '
        'reusable: $reusable, '
        'signature: $signature, '
        'accountName: $accountName, '
        'mobileMoneyNumber: $mobileMoneyNumber'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Authorization &&
        other.authorizationCode == authorizationCode &&
        other.bin == bin &&
        other.last4 == last4 &&
        other.expMonth == expMonth &&
        other.expYear == expYear &&
        other.channel == channel &&
        other.cardType == cardType &&
        other.bank == bank &&
        other.countryCode == countryCode &&
        other.brand == brand &&
        other.reusable == reusable &&
        other.signature == signature &&
        other.accountName == accountName &&
        other.mobileMoneyNumber == mobileMoneyNumber;
  }

  @override
  int get hashCode => Object.hash(
        authorizationCode,
        bin,
        last4,
        expMonth,
        expYear,
        channel,
        cardType,
        bank,
        countryCode,
        brand,
        reusable,
        signature,
        accountName,
        mobileMoneyNumber,
      );
}
