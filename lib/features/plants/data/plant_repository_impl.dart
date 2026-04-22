import 'package:flutter_web3_wallet/features/plants/data/data_sources/plant_remote_data_source.dart';
import 'package:flutter_web3_wallet/features/plants/domain/plant.dart';
import 'package:flutter_web3_wallet/features/plants/domain/plant_repository.dart';
import '../../../core/storage/in_memory_cache.dart';

class PlantRepositoryImpl implements PlantRepository {
  final PlantRemoteDataSource remoteDataSource;
  final InMemoryCache<List<Plant>> cache;

  PlantRepositoryImpl({
    required this.remoteDataSource,
    required this.cache,
  });

  @override
  Future<List<Plant>> getPlants() async {
    try {
      final plants = await remoteDataSource.getPlants();
      cache.save(plants);

      return plants;
    } catch (e) {
      if (cache.data != null) {
        return cache.data!;
      }
      rethrow;
    }
  }
}
