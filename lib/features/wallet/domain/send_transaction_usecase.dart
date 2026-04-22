import 'package:flutter_web3_wallet/features/wallet/domain/wallet_repository.dart';

class SendTransactionUseCase {
  final WalletRepository repository;

  SendTransactionUseCase(this.repository);

  Future<String> call({
    required String privateKey,
    required String toAddress,
    required double amount,
  }) {
    return repository.sendTransaction(
      privateKey: privateKey,
      toAddress: toAddress,
      amount: amount,
    );
  }
}
