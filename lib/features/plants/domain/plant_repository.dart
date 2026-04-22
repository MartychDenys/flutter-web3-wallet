import 'plant.dart';

abstract class PlantRepository {
  Future<List<Plant>> getPlants();
}
