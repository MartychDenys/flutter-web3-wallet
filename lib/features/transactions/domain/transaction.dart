enum TxType { eth, erc20 }
enum TxDirection { incoming, outgoing, self }

class WalletTransaction {
  final String hash;
  final String from;
  final String to;
  final double value;
  final String? tokenSymbol;
  final String? tokenName;
  final DateTime timestamp;
  final bool isError;
  final TxType type;
  final BigInt gasUsed;
  final BigInt gasPrice;

  const WalletTransaction({
    required this.hash,
    required this.from,
    required this.to,
    required this.value,
    required this.timestamp,
    required this.isError,
    required this.type,
    required this.gasUsed,
    required this.gasPrice,
    this.tokenSymbol,
    this.tokenName,
  });

  double get fee => (gasUsed * gasPrice).toDouble() / 1e18;

  TxDirection directionFor(String walletAddress) {
    final addr = walletAddress.toLowerCase();
    final f = from.toLowerCase();
    final t = to.toLowerCase();
    if (f == addr && t == addr) return TxDirection.self;
    if (f == addr) return TxDirection.outgoing;
    return TxDirection.incoming;
  }

  String get shortHash => '${hash.substring(0, 10)}...${hash.substring(hash.length - 6)}';
}
