import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:plant_care_app/features/plants/domain/plant.dart';
import 'package:plant_care_app/features/plants/domain/plant_repository.dart';
import 'package:plant_care_app/features/plants/domain/get_plants_usecase.dart';

// 🔥 створюємо mock
class MockPlantRepository extends Mock implements PlantRepository {}

void main() {
  late GetPlantsUseCase useCase;
  late MockPlantRepository mockRepository;

  setUp(() {
    mockRepository = MockPlantRepository();
    useCase = GetPlantsUseCase(mockRepository);
  });

  test('should return list of plants from repository', () async {
    final plants = [
      Plant(
        id: '1',
        name: 'Monstera',
        description: 'Water weekly',
      ),
      Plant(
        id: '2',
        name: 'Ficus',
        description: 'Needs sunlight',
      ),
    ];

    when(() => mockRepository.getPlants()).thenAnswer((_) async => plants);

    final result = await useCase();

    expect(result, plants);
    verify(() => mockRepository.getPlants()).called(1);
  });



}


