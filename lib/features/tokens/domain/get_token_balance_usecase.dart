import 'token_repository.dart';

class GetTokenBalanceUseCase {
  final TokenRepository repository;

  GetTokenBalanceUseCase(this.repository);

  Future<double> call({
    required String contractAddress,
    required String walletAddress,
  }) {
    return repository.getTokenBalance(contractAddress, walletAddress);
  }
}
