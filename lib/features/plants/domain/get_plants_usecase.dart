import 'plant.dart';
import 'plant_repository.dart';

class GetPlantsUseCase {
  final PlantRepository repository;

  GetPlantsUseCase(this.repository);

  Future<List<Plant>> call() {
    print('Call use case getPlants!!!!!');
    return repository.getPlants();
  }
}
