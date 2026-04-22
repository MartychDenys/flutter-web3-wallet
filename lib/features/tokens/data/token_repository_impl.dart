import 'package:flutter_web3_wallet/features/tokens/data/data_sources/token_remote_data_source.dart';
import 'package:flutter_web3_wallet/features/tokens/domain/token.dart';
import 'package:flutter_web3_wallet/features/tokens/domain/token_repository.dart';

class TokenRepositoryImpl implements TokenRepository {
  final TokenRemoteDataSource remoteDataSource;

  TokenRepositoryImpl(this.remoteDataSource);

  @override
  Future<Token> getTokenInfo(String contractAddress, String walletAddress) {
    return remoteDataSource.getTokenInfo(contractAddress, walletAddress);
  }

  @override
  Future<double> getTokenBalance(
    String contractAddress,
    String walletAddress,
  ) {
    return remoteDataSource.getTokenBalance(contractAddress, walletAddress);
  }

  @override
  Future<String> transferToken({
    required String privateKey,
    required String contractAddress,
    required String toAddress,
    required double amount,
  }) {
    return remoteDataSource.transferToken(
      privateKey: privateKey,
      contractAddress: contractAddress,
      toAddress: toAddress,
      amount: amount,
    );
  }

  @override
  Future<String> approveToken({
    required String privateKey,
    required String contractAddress,
    required String spenderAddress,
    required double amount,
  }) {
    return remoteDataSource.approveToken(
      privateKey: privateKey,
      contractAddress: contractAddress,
      spenderAddress: spenderAddress,
      amount: amount,
    );
  }

  @override
  Future<double> getAllowance({
    required String contractAddress,
    required String ownerAddress,
    required String spenderAddress,
  }) {
    return remoteDataSource.getAllowance(
      contractAddress: contractAddress,
      ownerAddress: ownerAddress,
      spenderAddress: spenderAddress,
    );
  }
}
