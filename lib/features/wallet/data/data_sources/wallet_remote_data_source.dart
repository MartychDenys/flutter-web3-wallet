import 'package:flutter_web3_wallet/core/web3/web3_service.dart';

class WalletRemoteDataSource {
  final Web3Service web3Service;

  WalletRemoteDataSource(this.web3Service);

  Future<double> getBalance(String address) {
    return web3Service.getBalance(address);
  }

  Future<String> sendTransaction({
    required String privateKey,
    required String toAddress,
    required double amount,
  }) {
    return web3Service.sendTransaction(
      privateKey: privateKey,
      toAddress: toAddress,
      amountInEth: amount,
    );
  }
}