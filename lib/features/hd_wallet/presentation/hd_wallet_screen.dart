import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web3_wallet/core/hd_wallet/hd_wallet_service.dart';
import 'package:flutter_web3_wallet/features/hd_wallet/presentation/hd_wallet_notifier.dart';
import 'package:flutter_web3_wallet/features/hd_wallet/presentation/hd_wallet_provider.dart';
import 'package:flutter_web3_wallet/features/wallet/presentation/wallet_provider.dart';

class HdWalletScreen extends ConsumerWidget {
  const HdWalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(hdWalletNotifierProvider);

    ref.listen(hdWalletNotifierProvider, (_, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () => ref.read(hdWalletNotifierProvider.notifier).clearError(),
            ),
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('HD Wallet'),
        centerTitle: true,
        actions: [
          if (state.hasWallet)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Clear wallet',
              onPressed: () => _confirmClear(context, ref),
            ),
        ],
      ),
      body: state.hasWallet
          ? _WalletView(state: state)
          : _SetupView(),
    );
  }

  void _confirmClear(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear wallet?'),
        content: const Text(
          'Make sure you have backed up your seed phrase before clearing.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              ref.read(hdWalletNotifierProvider.notifier).clearWallet();
            },
            child: const Text('Clear', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ─── Setup (no wallet yet) ────────────────────────────────

class _SetupView extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.account_balance_wallet_outlined, size: 72, color: Colors.indigo),
          const SizedBox(height: 16),
          const Text(
            'HD Wallet',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'One seed phrase → infinite accounts\nBIP39 + BIP44 (m/44\'/60\'/0\'/0/n)',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 40),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: () =>
                ref.read(hdWalletNotifierProvider.notifier).generateNewWallet(),
            icon: const Icon(Icons.add),
            label: const Text('Generate New Wallet', style: TextStyle(fontSize: 16)),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: () => _showImportSheet(context, ref),
            icon: const Icon(Icons.download_outlined),
            label: const Text('Import Seed Phrase', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  void _showImportSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ImportSheet(
        onImport: (mnemonic) {
          Navigator.pop(context);
          ref.read(hdWalletNotifierProvider.notifier).importFromMnemonic(mnemonic);
        },
      ),
    );
  }
}

// ─── Wallet view (wallet exists) ─────────────────────────

class _WalletView extends ConsumerWidget {
  final HdWalletState state;

  const _WalletView({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (state.mnemonic != null) _MnemonicCard(state: state, ref: ref),
          const SizedBox(height: 16),
          _AccountsSection(state: state),
        ],
      ),
    );
  }
}

// ─── Mnemonic card ────────────────────────────────────────

class _MnemonicCard extends StatelessWidget {
  final HdWalletState state;
  final WidgetRef ref;

  const _MnemonicCard({required this.state, required this.ref});

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(hdWalletNotifierProvider.notifier);
    final words = state.mnemonic!.split(' ');

    return Card(
      color: Colors.amber.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber, color: Colors.amber),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Secret Recovery Phrase',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                IconButton(
                  icon: Icon(state.mnemonicVisible ? Icons.visibility_off : Icons.visibility),
                  onPressed: notifier.toggleMnemonicVisibility,
                ),
              ],
            ),
            const Text(
              'Never share this phrase. Anyone with it has full access to your wallet.',
              style: TextStyle(color: Colors.orange, fontSize: 12),
            ),
            const SizedBox(height: 12),
            if (state.mnemonicVisible) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: words.asMap().entries.map((e) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.amber.shade300),
                    ),
                    child: Text(
                      '${e.key + 1}. ${e.value}',
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: state.mnemonic!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Copied! Store it safely and clear clipboard.'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy to clipboard'),
                ),
              ),
            ] else
              const Text(
                'Tap the eye icon to reveal your seed phrase',
                style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Accounts section ─────────────────────────────────────

class _AccountsSection extends ConsumerWidget {
  final HdWalletState state;

  const _AccountsSection({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Accounts',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () =>
                  ref.read(hdWalletNotifierProvider.notifier).addNextAccount(),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add account'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...state.accounts.asMap().entries.map(
          (e) => _AccountTile(
            account: e.value,
            isSelected: e.key == state.selectedIndex,
            onSelect: () {
              ref.read(hdWalletNotifierProvider.notifier).selectAccount(e.key);
              // Sync address to main wallet provider
              ref.read(addressInputProvider.notifier).state = e.value.address;
              ref.read(submittedAddressProvider.notifier).state = e.value.address;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Account ${e.key + 1} selected'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _AccountTile extends StatelessWidget {
  final HdAccount account;
  final bool isSelected;
  final VoidCallback onSelect;

  const _AccountTile({
    required this.account,
    required this.isSelected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isSelected ? Colors.indigo.shade50 : null,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isSelected ? Colors.indigo : Colors.grey.shade300,
          child: Text(
            '${account.index + 1}',
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          'Account ${account.index + 1}',
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText(
              account.address,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
            ),
            Text(
              account.derivationPath,
              style: const TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.copy, size: 18),
              tooltip: 'Copy address',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: account.address));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Address copied'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Colors.indigo),
          ],
        ),
        onTap: onSelect,
        isThreeLine: true,
      ),
    );
  }
}

// ─── Import sheet ─────────────────────────────────────────

class _ImportSheet extends StatefulWidget {
  final void Function(String) onImport;

  const _ImportSheet({required this.onImport});

  @override
  State<_ImportSheet> createState() => _ImportSheetState();
}

class _ImportSheetState extends State<_ImportSheet> {
  final _controller = TextEditingController();
  int _wordCount = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Import Seed Phrase',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Enter your 12 or 24-word recovery phrase',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'word1 word2 word3 ...',
              border: const OutlineInputBorder(),
              suffixText: '$_wordCount words',
            ),
            onChanged: (v) {
              setState(() {
                _wordCount = v.trim().isEmpty ? 0 : v.trim().split(RegExp(r'\s+')).length;
              });
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: (_wordCount == 12 || _wordCount == 24)
                ? () => widget.onImport(_controller.text)
                : null,
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
            child: const Text('Import', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}
