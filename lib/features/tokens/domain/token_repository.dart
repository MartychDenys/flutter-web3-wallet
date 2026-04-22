import 'token.dart';

abstract class TokenRepository {
  Future<Token> getTokenInfo(String contractAddress, String walletAddress);
  Future<double> getTokenBalance(String contractAddress, String walletAddress);
  Future<String> transferToken({
    required String privateKey,
    required String contractAddress,
    required String toAddress,
    required double amount,
  });
  Future<String> approveToken({
    required String privateKey,
    required String contractAddress,
    required String spenderAddress,
    required double amount,
  });
  Future<double> getAllowance({
    required String contractAddress,
    required String ownerAddress,
    required String spenderAddress,
  });
}
