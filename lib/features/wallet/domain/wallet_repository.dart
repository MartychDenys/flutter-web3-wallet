abstract class WalletRepository {
  Future<double> getBalance(String address);

  Future<String> sendTransaction({
    required String privateKey,
    required String toAddress,
    required double amount,
  });
}

