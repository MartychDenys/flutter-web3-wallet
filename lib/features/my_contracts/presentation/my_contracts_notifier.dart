import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web3_wallet/core/contracts/deployed_contracts.dart';
import 'package:flutter_web3_wallet/features/wallet/presentation/wallet_provider.dart';

class MyContractsState {
  final double? devTokenBalance;
  final BigInt? devNftTotalSupply;
  final bool isLoadingBalance;
  final bool isMinting;
  final bool isTransferring;
  final String? lastTxHash;
  final String? error;

  const MyContractsState({
    this.devTokenBalance,
    this.devNftTotalSupply,
    this.isLoadingBalance = false,
    this.isMinting = false,
    this.isTransferring = false,
    this.lastTxHash,
    this.error,
  });

  bool get isLoading => isLoadingBalance || isMinting || isTransferring;

  MyContractsState copyWith({
    double? devTokenBalance,
    BigInt? devNftTotalSupply,
    bool? isLoadingBalance,
    bool? isMinting,
    bool? isTransferring,
    String? lastTxHash,
    String? error,
    bool clearError = false,
    bool clearTx = false,
  }) {
    return MyContractsState(
      devTokenBalance: devTokenBalance ?? this.devTokenBalance,
      devNftTotalSupply: devNftTotalSupply ?? this.devNftTotalSupply,
      isLoadingBalance: isLoadingBalance ?? this.isLoadingBalance,
      isMinting: isMinting ?? this.isMinting,
      isTransferring: isTransferring ?? this.isTransferring,
      lastTxHash: clearTx ? null : (lastTxHash ?? this.lastTxHash),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class MyContractsNotifier extends StateNotifier<MyContractsState> {
  final Ref _ref;

  MyContractsNotifier(this._ref) : super(const MyContractsState());

  Future<void> loadData(String walletAddress) async {
    if (walletAddress.isEmpty) return;
    state = state.copyWith(isLoadingBalance: true, clearError: true);
    try {
      final web3 = _ref.read(web3ServiceProvider);
      final results = await Future.wait([
        web3.getTokenBalance(DeployedContracts.devTokenAddress, walletAddress),
        web3.getNftTotalSupply(DeployedContracts.devNftAddress),
      ]);
      state = state.copyWith(
        devTokenBalance: results[0] as double,
        devNftTotalSupply: results[1] as BigInt,
        isLoadingBalance: false,
      );
    } catch (e) {
      state = state.copyWith(isLoadingBalance: false, error: e.toString());
    }
  }

  Future<void> mintNft({
    required String privateKey,
    required String toAddress,
    String customUri = '',
  }) async {
    state = state.copyWith(isMinting: true, clearError: true, clearTx: true);
    try {
      final web3 = _ref.read(web3ServiceProvider);
      final txHash = await web3.mintNft(
        privateKey: privateKey,
        contractAddress: DeployedContracts.devNftAddress,
        toAddress: toAddress,
        customUri: customUri,
      );
      // Reload supply after mint
      final newSupply = await web3.getNftTotalSupply(DeployedContracts.devNftAddress);
      state = state.copyWith(
        isMinting: false,
        lastTxHash: txHash,
        devNftTotalSupply: newSupply,
      );
    } catch (e) {
      state = state.copyWith(isMinting: false, error: e.toString());
    }
  }

  Future<void> transferDevToken({
    required String privateKey,
    required String toAddress,
    required double amount,
    required String walletAddress,
  }) async {
    state = state.copyWith(isTransferring: true, clearError: true, clearTx: true);
    try {
      final web3 = _ref.read(web3ServiceProvider);
      final txHash = await web3.transferToken(
        privateKey: privateKey,
        contractAddress: DeployedContracts.devTokenAddress,
        toAddress: toAddress,
        amount: amount,
      );
      // Reload balance after transfer
      final newBalance = await web3.getTokenBalance(
        DeployedContracts.devTokenAddress,
        walletAddress,
      );
      state = state.copyWith(
        isTransferring: false,
        lastTxHash: txHash,
        devTokenBalance: newBalance,
      );
    } catch (e) {
      state = state.copyWith(isTransferring: false, error: e.toString());
    }
  }

  void clearError() => state = state.copyWith(clearError: true);
  void clearTx() => state = state.copyWith(clearTx: true);
}
