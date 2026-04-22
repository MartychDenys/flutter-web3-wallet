import 'package:dio/dio.dart';
import '../../domain/plant.dart';

class PlantRemoteDataSource {
  final Dio dio;

  PlantRemoteDataSource(this.dio);

  Future<List<Plant>> getPlants() async {
    final response = await dio.get('/plants');

    final data = response.data as List;

    return data.map((e) => Plant(
      id: e['id'],
      name: e['name'],
      description: e['description'],
    )).toList();
  }
}