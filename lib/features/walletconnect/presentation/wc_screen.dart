import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web3_wallet/features/wallet/presentation/wallet_provider.dart';
import 'package:flutter_web3_wallet/features/walletconnect/presentation/wc_provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';
import 'wc_request_dialog.dart';
import 'wc_session_proposal_dialog.dart';

class WcScreen extends ConsumerStatefulWidget {
  const WcScreen({super.key});

  @override
  ConsumerState<WcScreen> createState() => _WcScreenState();
}

class _WcScreenState extends ConsumerState<WcScreen> {
  final _uriController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(wcNotifierProvider.notifier).init();
    });
  }

  @override
  void dispose() {
    _uriController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wcState = ref.watch(wcNotifierProvider);
    final walletAddress = ref.watch(addressInputProvider);

    // Show proposal dialog when pending
    ref.listen(wcNotifierProvider, (prev, next) {
      if (next.pendingProposal != null && prev?.pendingProposal == null) {
        _showProposalDialog(context, next.pendingProposal!, walletAddress);
      }
      if (next.pendingRequest != null && prev?.pendingRequest == null) {
        _showRequestDialog(context, next.pendingRequest!, walletAddress);
      }
      if (next.error != null && prev?.error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () => ref.read(wcNotifierProvider.notifier).clearError(),
            ),
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('WalletConnect')),
      body: !wcState.isInitialized
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (walletAddress.isEmpty)
                    const _WalletAddressWarning(),

                  const SizedBox(height: 8),

                  _ConnectCard(
                    uriController: _uriController,
                    isLoading: wcState.isLoading,
                    onConnect: (uri) =>
                        ref.read(wcNotifierProvider.notifier).pair(uri),
                    onScan: () => _openQrScanner(context),
                  ),

                  const SizedBox(height: 24),

                  if (wcState.activeSessions.isEmpty)
                    const _EmptySessionsPlaceholder()
                  else ...[
                    const Text(
                      'Connected dApps',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...wcState.activeSessions.map(
                      (s) => _SessionTile(
                        session: s,
                        onDisconnect: () =>
                            ref.read(wcNotifierProvider.notifier).disconnect(s.topic),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  void _showProposalDialog(
    BuildContext context,
    SessionProposalEvent proposal,
    String walletAddress,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => WcSessionProposalDialog(
        proposal: proposal,
        walletAddress: walletAddress,
        onApprove: () {
          Navigator.pop(context);
          ref.read(wcNotifierProvider.notifier).approveSession(
                proposal: proposal,
                walletAddress: walletAddress,
              );
        },
        onReject: () {
          Navigator.pop(context);
          ref.read(wcNotifierProvider.notifier).rejectSession(proposal);
        },
      ),
    );
  }

  void _showRequestDialog(BuildContext context, request, String walletAddress) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => WcRequestDialog(
        request: request,
        walletAddress: walletAddress,
        onApprove: (privateKey) {
          Navigator.pop(context);
          final web3 = ref.read(web3ServiceProvider).client;
          ref.read(wcNotifierProvider.notifier).approveRequest(
                request: request,
                privateKey: privateKey,
                web3Client: web3,
              );
        },
        onReject: () {
          Navigator.pop(context);
          ref.read(wcNotifierProvider.notifier).rejectRequest(request);
        },
      ),
    );
  }

  void _openQrScanner(BuildContext context) async {
    final uri = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const _QrScannerScreen()),
    );
    if (uri != null && uri.isNotEmpty) {
      _uriController.text = uri;
      if (mounted) {
        ref.read(wcNotifierProvider.notifier).pair(uri);
      }
    }
  }
}

class _ConnectCard extends StatelessWidget {
  final TextEditingController uriController;
  final bool isLoading;
  final void Function(String) onConnect;
  final VoidCallback onScan;

  const _ConnectCard({
    required this.uriController,
    required this.isLoading,
    required this.onConnect,
    required this.onScan,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Connect to dApp',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            const Text(
              'Paste a WalletConnect URI or scan a QR code from any dApp',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: uriController,
                    decoration: const InputDecoration(
                      hintText: 'wc:...',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () async {
                    final data = await Clipboard.getData(Clipboard.kTextPlain);
                    if (data?.text != null) {
                      uriController.text = data!.text!;
                    }
                  },
                  icon: const Icon(Icons.paste),
                  tooltip: 'Paste from clipboard',
                ),
                IconButton(
                  onPressed: onScan,
                  icon: const Icon(Icons.qr_code_scanner),
                  tooltip: 'Scan QR',
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isLoading
                    ? null
                    : () {
                        final uri = uriController.text.trim();
                        if (uri.isNotEmpty) onConnect(uri);
                      },
                icon: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.link),
                label: Text(isLoading ? 'Connecting...' : 'Connect'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  final SessionData session;
  final VoidCallback onDisconnect;

  const _SessionTile({required this.session, required this.onDisconnect});

  @override
  Widget build(BuildContext context) {
    final peer = session.peer.metadata;
    return Card(
      child: ListTile(
        leading: peer.icons.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(peer.icons.first, width: 40, height: 40,
                    errorBuilder: (_, __, ___) => const Icon(Icons.web)),
              )
            : const CircleAvatar(child: Icon(Icons.web)),
        title: Text(peer.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(peer.url, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: IconButton(
          icon: const Icon(Icons.link_off, color: Colors.red),
          onPressed: onDisconnect,
          tooltip: 'Disconnect',
        ),
      ),
    );
  }
}

class _EmptySessionsPlaceholder extends StatelessWidget {
  const _EmptySessionsPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 32),
          Icon(Icons.link_off, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          const Text('No connected dApps',
              style: TextStyle(color: Colors.grey, fontSize: 16)),
          const SizedBox(height: 4),
          const Text(
            'Connect to Uniswap, OpenSea, or any WalletConnect dApp',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _WalletAddressWarning extends StatelessWidget {
  const _WalletAddressWarning();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: const Row(
        children: [
          Icon(Icons.warning_amber, color: Colors.orange),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Enter your wallet address in the Wallet tab first',
              style: TextStyle(color: Colors.orange, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _QrScannerScreen extends StatefulWidget {
  const _QrScannerScreen();

  @override
  State<_QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<_QrScannerScreen> {
  bool _scanned = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR Code')),
      body: MobileScanner(
        onDetect: (capture) {
          if (_scanned) return;
          final barcode = capture.barcodes.firstOrNull;
          final value = barcode?.rawValue;
          if (value != null && value.startsWith('wc:')) {
            _scanned = true;
            Navigator.pop(context, value);
          }
        },
      ),
    );
  }
}
