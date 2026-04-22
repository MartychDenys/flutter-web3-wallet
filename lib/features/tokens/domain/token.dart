class Token {
  final String contractAddress;
  final String symbol;
  final String name;
  final int decimals;
  final double balance;

  const Token({
    required this.contractAddress,
    required this.symbol,
    required this.name,
    required this.decimals,
    required this.balance,
  });

  Token copyWith({double? balance}) {
    return Token(
      contractAddress: contractAddress,
      symbol: symbol,
      name: name,
      decimals: decimals,
      balance: balance ?? this.balance,
    );
  }
}

/// Known Sepolia testnet tokens for easy testing
class SepoliaTokens {
  static const usdc = '0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238';
  static const link = '0x779877A7B0D9E8603169DdbD7836e478b4624789';
  static const weth = '0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14';
}
