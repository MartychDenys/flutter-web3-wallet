import 'dart:typed_data';

import 'package:bip32/bip32.dart' as bip32;
import 'package:bip39/bip39.dart' as bip39;
import 'package:web3dart/web3dart.dart';

// Standard Ethereum BIP44 derivation path: m/44'/60'/0'/0/{index}
const _ethDerivationPath = "m/44'/60'/0'/0";

class HdAccount {
  final int index;
  final String address;
  final String privateKey;
  final String derivationPath;

  const HdAccount({
    required this.index,
    required this.address,
    required this.privateKey,
    required this.derivationPath,
  });

  String get shortAddress =>
      '${address.substring(0, 8)}...${address.substring(address.length - 6)}';
}

class HdWalletService {
  /// Generates a new random 12-word mnemonic
  String generateMnemonic() => bip39.generateMnemonic();

  /// Generates a 24-word mnemonic for higher security
  String generateMnemonic24() => bip39.generateMnemonic(strength: 256);

  /// Validates a mnemonic phrase
  bool validateMnemonic(String mnemonic) => bip39.validateMnemonic(mnemonic);

  /// Derives a single account at the given index
  HdAccount deriveAccount(String mnemonic, {int index = 0}) {
    _assertValid(mnemonic);
    final node = _rootNode(mnemonic);
    return _accountFromNode(node, index);
  }

  /// Derives multiple accounts (for multi-account wallet UI)
  List<HdAccount> deriveAccounts(String mnemonic, {int count = 5}) {
    _assertValid(mnemonic);
    final node = _rootNode(mnemonic);
    return List.generate(count, (i) => _accountFromNode(node, i));
  }

  /// Returns the private key hex for a specific account
  String privateKeyForAccount(String mnemonic, {int index = 0}) {
    return deriveAccount(mnemonic, index: index).privateKey;
  }

  // ─── Private ──────────────────────────────────────────────

  bip32.BIP32 _rootNode(String mnemonic) {
    final seed = bip39.mnemonicToSeed(mnemonic);
    return bip32.BIP32.fromSeed(seed);
  }

  HdAccount _accountFromNode(bip32.BIP32 root, int index) {
    final path = '$_ethDerivationPath/$index';
    final child = root.derivePath(path);
    final privateKeyBytes = child.privateKey!;
    final credentials = EthPrivateKey(privateKeyBytes);

    return HdAccount(
      index: index,
      address: credentials.address.hexEip55,
      privateKey: _bytesToHex(privateKeyBytes),
      derivationPath: path,
    );
  }

  String _bytesToHex(Uint8List bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  void _assertValid(String mnemonic) {
    if (!validateMnemonic(mnemonic)) {
      throw ArgumentError('Invalid mnemonic phrase');
    }
  }
}
