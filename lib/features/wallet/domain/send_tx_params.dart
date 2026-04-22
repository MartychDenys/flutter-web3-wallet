class SendTxParams {
  final String privateKey;
  final String toAddress;
  final double amount;

  SendTxParams({
    required this.privateKey,
    required this.toAddress,
    required this.amount,
  });
}
