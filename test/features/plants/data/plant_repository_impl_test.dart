import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:plant_care_app/features/plants/data/plant_repository_impl.dart';
import 'package:plant_care_app/features/plants/data/data_sources/plant_remote_data_source.dart';
import 'package:plant_care_app/core/storage/in_memory_cache.dart';
import 'package:plant_care_app/features/plants/domain/plant.dart';

class MockRemoteDataSource extends Mock implements PlantRemoteDataSource {}

void main() {
  late PlantRepositoryImpl repository;
  late MockRemoteDataSource mockRemote;

  setUp(() {
    mockRemote = MockRemoteDataSource();

    repository = PlantRepositoryImpl(
      remoteDataSource: mockRemote,
      cache: InMemoryCache(),
    );
  });

  test('should return data from remote and cache it', () async {
    final plants = [
      Plant(id: '1', name: 'Monstera', description: 'Test'),
    ];

    when(() => mockRemote.getPlants())
        .thenAnswer((_) async => plants);

    final result = await repository.getPlants();

    expect(result, plants);
    verify(() => mockRemote.getPlants()).called(1);
  });
}