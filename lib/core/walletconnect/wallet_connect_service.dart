import 'dart:convert';
import 'dart:typed_data';

import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';

const _wcProjectId = 'YOUR_WC_PROJECT_ID'; // cloud.walletconnect.com

const wcSupportedMethods = [
  'personal_sign',
  'eth_sign',
  'eth_sendTransaction',
  'eth_signTransaction',
  'eth_signTypedData_v4',
];

const wcSupportedEvents = ['chainChanged', 'accountsChanged'];

class WalletConnectService {
  Web3Wallet? _wallet;

  Web3Wallet get wallet {
    assert(_wallet != null, 'WalletConnectService not initialized');
    return _wallet!;
  }

  bool get isInitialized => _wallet != null;

  Future<void> init() async {
    _wallet = await Web3Wallet.createInstance(
      projectId: _wcProjectId,
      metadata: const PairingMetadata(
        name: 'Flutter Web3 Wallet',
        description: 'Web3 wallet built with Flutter + Riverpod',
        url: 'https://walletconnect.com',
        icons: ['https://walletconnect.com/walletconnect-logo.png'],
      ),
    );
  }

  Future<void> pair(String uri) async {
    await wallet.pair(uri: Uri.parse(uri));
  }

  Future<void> approveSession({
    required SessionProposalEvent proposal,
    required String walletAddress,
    int chainId = 11155111,
  }) async {
    final approved = buildNamespaces(
      proposal: proposal,
      walletAddress: walletAddress,
      chainId: chainId,
    );
    await wallet.approveSession(id: proposal.id, namespaces: approved);
  }

  Future<void> rejectSession(SessionProposalEvent proposal) async {
    await wallet.rejectSession(
      id: proposal.id,
      reason: Errors.getSdkError(Errors.USER_REJECTED),
    );
  }

  Future<void> disconnectSession(String topic) async {
    await wallet.disconnectSession(
      topic: topic,
      reason: Errors.getSdkError(Errors.USER_DISCONNECTED),
    );
  }

  Future<void> respondSuccess({
    required String topic,
    required int requestId,
    required dynamic result,
  }) async {
    await wallet.respondSessionRequest(
      topic: topic,
      response: JsonRpcResponse(id: requestId, result: result),
    );
  }

  Future<void> respondError({
    required String topic,
    required int requestId,
    String message = 'User rejected',
  }) async {
    await wallet.respondSessionRequest(
      topic: topic,
      response: JsonRpcResponse(
        id: requestId,
        error: JsonRpcError(code: 4001, message: message),
      ),
    );
  }

  List<SessionData> getActiveSessions() {
    return wallet.sessions.getAll();
  }

  // ─── Signing ──────────────────────────────────────────────

  /// personal_sign: signs with Ethereum prefix
  String personalSign(String privateKey, String message) {
    final cleanKey = privateKey.startsWith('0x') ? privateKey.substring(2) : privateKey;
    final keyBytes = hexToBytes(cleanKey);
    final msgBytes = _hexToBytes(message);
    final prefixedHash = _personalSignHash(msgBytes);
    final sig = sign(prefixedHash, keyBytes);
    return _signatureToHex(sig);
  }

  /// eth_sendTransaction: build and broadcast
  Future<String> sendTransactionRequest({
    required String privateKey,
    required Map<String, dynamic> txParams,
    required Web3Client web3Client,
  }) async {
    final credentials = EthPrivateKey.fromHex(privateKey);
    final to = EthereumAddress.fromHex(txParams['to'] as String);

    final valueHex = txParams['value'] as String?;
    final value = valueHex != null && valueHex.isNotEmpty
        ? EtherAmount.fromBigInt(EtherUnit.wei, _parseBigIntHex(valueHex))
        : EtherAmount.zero();

    final dataHex = txParams['data'] as String?;
    final data = dataHex != null && dataHex.isNotEmpty && dataHex != '0x'
        ? _hexToBytes(dataHex)
        : null;

    final gasHex = txParams['gas'] as String?;
    final gasLimit = gasHex != null ? _parseBigIntHex(gasHex).toInt() : null;

    final txHash = await web3Client.sendTransaction(
      credentials,
      Transaction(
        to: to,
        value: value,
        data: data,
        maxGas: gasLimit,
      ),
      chainId: 11155111,
    );
    return txHash;
  }

  // ─── Helpers ──────────────────────────────────────────────

  Map<String, Namespace> buildNamespaces({
    required SessionProposalEvent proposal,
    required String walletAddress,
    required int chainId,
  }) {
    final requiredNamespaces = proposal.params.requiredNamespaces;
    final optionalNamespaces = proposal.params.optionalNamespaces;

    final Map<String, Namespace> result = {};

    // Process eip155 namespace (Ethereum)
    final eip155Key = 'eip155';
    final required = requiredNamespaces[eip155Key];
    final optional = optionalNamespaces[eip155Key];

    final methods = <String>{
      ...?required?.methods,
      ...?optional?.methods,
      ...wcSupportedMethods,
    }.where((m) => wcSupportedMethods.contains(m)).toList();

    final events = <String>{
      ...?required?.events,
      ...?optional?.events,
      ...wcSupportedEvents,
    }.toList();

    result[eip155Key] = Namespace(
      accounts: ['$eip155Key:$chainId:$walletAddress'],
      methods: methods,
      events: events,
    );

    return result;
  }

  Uint8List _personalSignHash(Uint8List message) {
    final prefix = '\x19Ethereum Signed Message:\n${message.length}';
    final prefixBytes = utf8.encode(prefix);
    return keccak256(Uint8List.fromList([...prefixBytes, ...message]));
  }

  Uint8List _hexToBytes(String hex) {
    final clean = hex.startsWith('0x') ? hex.substring(2) : hex;
    if (clean.isEmpty) return Uint8List(0);
    return Uint8List.fromList(
      List.generate(clean.length ~/ 2, (i) => int.parse(clean.substring(i * 2, i * 2 + 2), radix: 16)),
    );
  }

  BigInt _parseBigIntHex(String hex) {
    final clean = hex.startsWith('0x') ? hex.substring(2) : hex;
    return BigInt.parse(clean, radix: 16);
  }

  String _signatureToHex(MsgSignature sig) {
    final r = _padHex(sig.r.toRadixString(16), 64);
    final s = _padHex(sig.s.toRadixString(16), 64);
    final v = sig.v.toRadixString(16).padLeft(2, '0');
    return '0x$r$s$v';
  }

  String _padHex(String hex, int length) => hex.padLeft(length, '0');
}
