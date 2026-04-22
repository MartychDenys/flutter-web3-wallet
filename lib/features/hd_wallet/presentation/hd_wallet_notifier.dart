import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web3_wallet/core/hd_wallet/hd_wallet_service.dart';

class HdWalletState {
  final String? mnemonic;
  final List<HdAccount> accounts;
  final int selectedIndex;
  final bool mnemonicVisible;
  final String? error;

  const HdWalletState({
    this.mnemonic,
    this.accounts = const [],
    this.selectedIndex = 0,
    this.mnemonicVisible = false,
    this.error,
  });

  HdAccount? get selectedAccount =>
      accounts.isEmpty ? null : accounts[selectedIndex];

  bool get hasWallet => mnemonic != null && accounts.isNotEmpty;

  HdWalletState copyWith({
    String? mnemonic,
    List<HdAccount>? accounts,
    int? selectedIndex,
    bool? mnemonicVisible,
    String? error,
    bool clearError = false,
  }) {
    return HdWalletState(
      mnemonic: mnemonic ?? this.mnemonic,
      accounts: accounts ?? this.accounts,
      selectedIndex: selectedIndex ?? this.selectedIndex,
      mnemonicVisible: mnemonicVisible ?? this.mnemonicVisible,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class HdWalletNotifier extends StateNotifier<HdWalletState> {
  final HdWalletService _service;

  HdWalletNotifier(this._service) : super(const HdWalletState());

  void generateNewWallet() {
    try {
      final mnemonic = _service.generateMnemonic();
      final accounts = _service.deriveAccounts(mnemonic);
      state = HdWalletState(
        mnemonic: mnemonic,
        accounts: accounts,
        mnemonicVisible: true,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void importFromMnemonic(String mnemonic) {
    try {
      final trimmed = mnemonic.trim().toLowerCase();
      if (!_service.validateMnemonic(trimmed)) {
        state = state.copyWith(error: 'Invalid mnemonic phrase. Check all words.');
        return;
      }
      final accounts = _service.deriveAccounts(trimmed);
      state = HdWalletState(
        mnemonic: trimmed,
        accounts: accounts,
        mnemonicVisible: false,
      );
    } catch (e) {
      state = state.copyWith(error: 'Import failed: $e');
    }
  }

  void selectAccount(int index) {
    if (index < 0 || index >= state.accounts.length) return;
    state = state.copyWith(selectedIndex: index);
  }

  void addNextAccount() {
    final mnemonic = state.mnemonic;
    if (mnemonic == null) return;
    final newIndex = state.accounts.length;
    final newAccount = _service.deriveAccount(mnemonic, index: newIndex);
    state = state.copyWith(
      accounts: [...state.accounts, newAccount],
    );
  }

  void toggleMnemonicVisibility() {
    state = state.copyWith(mnemonicVisible: !state.mnemonicVisible);
  }

  void clearWallet() {
    state = const HdWalletState();
  }

  void clearError() => state = state.copyWith(clearError: true);
}
