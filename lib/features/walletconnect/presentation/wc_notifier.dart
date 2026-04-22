import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web3_wallet/core/walletconnect/wallet_connect_service.dart';
import 'package:flutter_web3_wallet/features/walletconnect/domain/wc_session_request.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';

class WcState {
  final bool isInitialized;
  final bool isLoading;
  final String? error;
  final List<SessionData> activeSessions;
  final SessionProposalEvent? pendingProposal;
  final WcSessionRequest? pendingRequest;

  const WcState({
    this.isInitialized = false,
    this.isLoading = false,
    this.error,
    this.activeSessions = const [],
    this.pendingProposal,
    this.pendingRequest,
  });

  WcState copyWith({
    bool? isInitialized,
    bool? isLoading,
    String? error,
    List<SessionData>? activeSessions,
    SessionProposalEvent? pendingProposal,
    WcSessionRequest? pendingRequest,
    bool clearProposal = false,
    bool clearRequest = false,
    bool clearError = false,
  }) {
    return WcState(
      isInitialized: isInitialized ?? this.isInitialized,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      activeSessions: activeSessions ?? this.activeSessions,
      pendingProposal: clearProposal ? null : (pendingProposal ?? this.pendingProposal),
      pendingRequest: clearRequest ? null : (pendingRequest ?? this.pendingRequest),
    );
  }
}

class WcNotifier extends StateNotifier<WcState> {
  final WalletConnectService _service;

  WcNotifier(this._service) : super(const WcState());

  Future<void> init() async {
    if (state.isInitialized) return;
    state = state.copyWith(isLoading: true);
    try {
      await _service.init();
      _subscribeToEvents();
      state = state.copyWith(
        isInitialized: true,
        isLoading: false,
        activeSessions: _service.getActiveSessions(),
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void _subscribeToEvents() {
    _service.wallet.onSessionProposal.subscribe((event) {
      if (event == null) return;
      state = state.copyWith(pendingProposal: event);
    });

    _service.wallet.onSessionRequest.subscribe((event) {
      if (event == null) return;
      final request = WcSessionRequest(
        event: event,
        type: WcSessionRequest.typeFromMethod(event.method),
      );
      state = state.copyWith(pendingRequest: request);
    });

    _service.wallet.onSessionDelete.subscribe((_) {
      state = state.copyWith(activeSessions: _service.getActiveSessions());
    });
  }

  Future<void> pair(String uri) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _service.pair(uri);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Pairing failed: $e');
    }
  }

  Future<void> approveSession({
    required SessionProposalEvent proposal,
    required String walletAddress,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      await _service.approveSession(
        proposal: proposal,
        walletAddress: walletAddress,
      );
      state = state.copyWith(
        isLoading: false,
        activeSessions: _service.getActiveSessions(),
        clearProposal: true,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Approve failed: $e');
    }
  }

  Future<void> rejectSession(SessionProposalEvent proposal) async {
    await _service.rejectSession(proposal);
    state = state.copyWith(clearProposal: true);
  }

  Future<void> approveRequest({
    required WcSessionRequest request,
    required String privateKey,
    required Web3Client web3Client,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final result = await _handleRequest(
        request: request,
        privateKey: privateKey,
        web3Client: web3Client,
      );
      await _service.respondSuccess(
        topic: request.topic,
        requestId: request.id,
        result: result,
      );
      state = state.copyWith(isLoading: false, clearRequest: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Request failed: $e');
      await _service.respondError(topic: request.topic, requestId: request.id, message: '$e');
      state = state.copyWith(clearRequest: true);
    }
  }

  Future<void> rejectRequest(WcSessionRequest request) async {
    await _service.respondError(topic: request.topic, requestId: request.id);
    state = state.copyWith(clearRequest: true);
  }

  Future<void> disconnect(String topic) async {
    await _service.disconnectSession(topic);
    state = state.copyWith(activeSessions: _service.getActiveSessions());
  }

  void clearError() => state = state.copyWith(clearError: true);

  Future<dynamic> _handleRequest({
    required WcSessionRequest request,
    required String privateKey,
    required Web3Client web3Client,
  }) async {
    final params = (request.params as List<dynamic>);
    switch (request.type) {
      case WcRequestType.personalSign:
        // params[0] = message, params[1] = address
        final message = params[0] as String;
        return _service.personalSign(privateKey, message);

      case WcRequestType.ethSign:
        // params[0] = address, params[1] = message
        final message = params[1] as String;
        return _service.personalSign(privateKey, message);

      case WcRequestType.sendTransaction:
        final txParams = params[0] as Map<String, dynamic>;
        return _service.sendTransactionRequest(
          privateKey: privateKey,
          txParams: txParams,
          web3Client: web3Client,
        );

      case WcRequestType.signTransaction:
        // Sign but don't send — return signed hex
        final txParams = params[0] as Map<String, dynamic>;
        return _service.sendTransactionRequest(
          privateKey: privateKey,
          txParams: txParams,
          web3Client: web3Client,
        );

      case WcRequestType.signTypedData:
        // params[0] = address, params[1] = typed data JSON
        // For now return a basic sign — full EIP-712 is complex
        final data = params[1] as String;
        return _service.personalSign(privateKey, data);

      case WcRequestType.unknown:
        throw UnsupportedError('Method not supported: ${request.method}');
    }
  }
}
