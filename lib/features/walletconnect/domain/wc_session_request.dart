import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';

enum WcRequestType { personalSign, ethSign, sendTransaction, signTransaction, signTypedData, unknown }

class WcSessionRequest {
  final SessionRequestEvent event;
  final WcRequestType type;

  const WcSessionRequest({required this.event, required this.type});

  String get topic => event.topic;
  int get id => event.id;
  String get method => event.method;
  dynamic get params => event.params;

  static WcRequestType typeFromMethod(String method) {
    switch (method) {
      case 'personal_sign': return WcRequestType.personalSign;
      case 'eth_sign': return WcRequestType.ethSign;
      case 'eth_sendTransaction': return WcRequestType.sendTransaction;
      case 'eth_signTransaction': return WcRequestType.signTransaction;
      case 'eth_signTypedData_v4': return WcRequestType.signTypedData;
      default: return WcRequestType.unknown;
    }
  }

  String get displayMethod {
    switch (type) {
      case WcRequestType.personalSign: return 'Sign Message';
      case WcRequestType.ethSign: return 'Sign Message (eth_sign)';
      case WcRequestType.sendTransaction: return 'Send Transaction';
      case WcRequestType.signTransaction: return 'Sign Transaction';
      case WcRequestType.signTypedData: return 'Sign Typed Data (EIP-712)';
      case WcRequestType.unknown: return method;
    }
  }
}
