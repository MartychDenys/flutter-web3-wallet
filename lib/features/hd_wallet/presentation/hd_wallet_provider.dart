import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web3_wallet/core/hd_wallet/hd_wallet_service.dart';
import 'package:flutter_web3_wallet/features/hd_wallet/presentation/hd_wallet_notifier.dart';

final hdWalletServiceProvider = Provider<HdWalletService>((ref) {
  return HdWalletService();
});

final hdWalletNotifierProvider =
    StateNotifierProvider<HdWalletNotifier, HdWalletState>((ref) {
  return HdWalletNotifier(ref.read(hdWalletServiceProvider));
});
