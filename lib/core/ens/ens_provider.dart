import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'ens_service.dart';

final ensServiceProvider = Provider((ref) => EnsService());

final ensResolveProvider =
    FutureProvider.autoDispose.family<String?, String>((ref, name) {
  if (name.isEmpty) return Future.value(null);
  final service = ref.read(ensServiceProvider);
  if (!service.isEnsName(name)) return Future.value(null);
  return service.resolve(name);
});
