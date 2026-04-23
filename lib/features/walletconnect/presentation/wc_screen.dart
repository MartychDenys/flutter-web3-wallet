import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web3_wallet/core/theme/app_theme.dart';
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
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
      appBar: AppBar(title: const Text('WalletConnect'), centerTitle: true),
      body: !wcState.isInitialized
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (walletAddress.isEmpty) const _WalletAddressWarning(),

                  const SizedBox(height: 8),

                  _ConnectCard(
                    uriController: _uriController,
                    isLoading: wcState.isLoading,
                    onConnect: (uri) => ref.read(wcNotifierProvider.notifier).pair(uri),
                    onScan: () => _openQrScanner(context),
                  ),

                  const SizedBox(height: 24),

                  if (wcState.activeSessions.isEmpty)
                    const _EmptySessionsPlaceholder()
                  else ...[
                    const Text(
                      'Connected dApps',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...wcState.activeSessions.map(
                      (s) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _SessionTile(
                          session: s,
                          onDisconnect: () =>
                              ref.read(wcNotifierProvider.notifier).disconnect(s.topic),
                        ),
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.link_rounded, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Connect to dApp',
                    style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  Text(
                    'Paste URI or scan QR code',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: uriController,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: 'wc:...',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _IconActionButton(
                icon: Icons.paste_outlined,
                tooltip: 'Paste',
                onTap: () async {
                  final data = await Clipboard.getData(Clipboard.kTextPlain);
                  if (data?.text != null) uriController.text = data!.text!;
                },
              ),
              const SizedBox(width: 6),
              _IconActionButton(
                icon: Icons.qr_code_scanner_outlined,
                tooltip: 'Scan QR',
                onTap: onScan,
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 46,
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
                  : const Icon(Icons.link_rounded, size: 18),
              label: Text(isLoading ? 'Connecting...' : 'Connect'),
            ),
          ),
        ],
      ),
    );
  }
}

class _IconActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _IconActionButton({required this.icon, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Icon(icon, size: 20, color: AppColors.textSecondary),
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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: peer.icons.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: Image.network(
                      peer.icons.first,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.web_outlined, color: AppColors.textSecondary, size: 22),
                    ),
                  )
                : const Icon(Icons.web_outlined, color: AppColors.textSecondary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  peer.name,
                  style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  peer.url,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onDisconnect,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.error.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.error.withAlpha(60)),
              ),
              child: const Text(
                'Disconnect',
                style: TextStyle(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
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
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: const Icon(Icons.link_off_outlined, size: 36, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          const Text(
            'No connected dApps',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          const Text(
            'Connect to Uniswap, OpenSea,\nor any WalletConnect dApp',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFF9500).withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFF9500).withAlpha(60)),
      ),
      child: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Color(0xFFFF9500), size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Enter your wallet address in the Wallet tab first',
              style: TextStyle(color: Color(0xFFFF9500), fontSize: 13),
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
      appBar: AppBar(title: const Text('Scan QR Code'), centerTitle: true),
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
