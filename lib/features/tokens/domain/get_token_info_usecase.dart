import 'token.dart';
import 'token_repository.dart';

class GetTokenInfoUseCase {
  final TokenRepository repository;

  GetTokenInfoUseCase(this.repository);

  Future<Token> call({
    required String contractAddress,
    required String walletAddress,
  }) {
    return repository.getTokenInfo(contractAddress, walletAddress);
  }
}
