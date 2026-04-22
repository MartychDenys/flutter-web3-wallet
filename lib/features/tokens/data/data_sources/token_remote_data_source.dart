import 'package:flutter_web3_wallet/core/web3/web3_service.dart';
import 'package:flutter_web3_wallet/features/tokens/domain/token.dart';

class TokenRemoteDataSource {
  final Web3Service web3Service;

  TokenRemoteDataSource(this.web3Service);

  Future<Token> getTokenInfo(
    String contractAddress,
    String walletAddress,
  ) async {
    final info = await web3Service.getTokenInfo(contractAddress, walletAddress);
    return Token(
      contractAddress: contractAddress,
      name: info['name'] as String,
      symbol: info['symbol'] as String,
      decimals: info['decimals'] as int,
      balance: info['balance'] as double,
    );
  }

  Future<double> getTokenBalance(
    String contractAddress,
    String walletAddress,
  ) {
    return web3Service.getTokenBalance(contractAddress, walletAddress);
  }

  Future<String> transferToken({
    required String privateKey,
    required String contractAddress,
    required String toAddress,
    required double amount,
  }) {
    return web3Service.transferToken(
      privateKey: privateKey,
      contractAddress: contractAddress,
      toAddress: toAddress,
      amount: amount,
    );
  }

  Future<String> approveToken({
    required String privateKey,
    required String contractAddress,
    required String spenderAddress,
    required double amount,
  }) {
    return web3Service.approveToken(
      privateKey: privateKey,
      contractAddress: contractAddress,
      spenderAddress: spenderAddress,
      amount: amount,
    );
  }

  Future<double> getAllowance({
    required String contractAddress,
    required String ownerAddress,
    required String spenderAddress,
  }) {
    return web3Service.getAllowance(
      contractAddress: contractAddress,
      ownerAddress: ownerAddress,
      spenderAddress: spenderAddress,
    );
  }
}
