import 'package:flutter_web3_wallet/features/wallet/domain/wallet_repository.dart';

class GetBalanceUseCase {
  final WalletRepository repository;

  GetBalanceUseCase(this.repository);

  Future<double> call(String address) {
    return repository.getBalance(address);
  }
}
