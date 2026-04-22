import 'token_repository.dart';

class TransferTokenUseCase {
  final TokenRepository repository;

  TransferTokenUseCase(this.repository);

  Future<String> call({
    required String privateKey,
    required String contractAddress,
    required String toAddress,
    required double amount,
  }) {
    return repository.transferToken(
      privateKey: privateKey,
      contractAddress: contractAddress,
      toAddress: toAddress,
      amount: amount,
    );
  }
}
