import 'package:flutter_web3_wallet/features/wallet/data/data_sources/wallet_remote_data_source.dart';
import 'package:flutter_web3_wallet/features/wallet/domain/wallet_repository.dart';

class WalletRepositoryImpl implements WalletRepository {
  final WalletRemoteDataSource remoteDataSource;

  WalletRepositoryImpl(this.remoteDataSource);

  @override
  Future<double> getBalance(String address) {
    return remoteDataSource.getBalance(address);
  }

  @override
  Future<String> sendTransaction({
    required String privateKey,
    required String toAddress,
    required double amount,
  }) {
    return remoteDataSource.sendTransaction(
      privateKey: privateKey,
      toAddress: toAddress,
      amount: amount,
    );
  }
}
