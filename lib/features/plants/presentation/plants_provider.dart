import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web3_wallet/core/storage/in_memory_cache.dart';
import 'package:flutter_web3_wallet/features/plants/data/data_sources/plant_remote_data_source.dart';

import '../data/plant_repository_impl.dart';
import '../domain/get_plants_usecase.dart';
import '../domain/plant.dart';

final dioProvider = Provider((ref) => Dio());

// repository
final plantRepositoryProvider = Provider((ref) {
  return PlantRepositoryImpl(
    remoteDataSource: PlantRemoteDataSource(ref.read(dioProvider)),
    cache: InMemoryCache(),
  );
});

// useCase
final getPlantsUseCaseProvider = Provider((ref) => GetPlantsUseCase(ref.read(plantRepositoryProvider)));

// state
final plantsProvider = FutureProvider<List<Plant>>((ref) async {
  final useCase = ref.read(getPlantsUseCaseProvider);
  print('FutureProvider= ${useCase()}');
  return useCase();
});


