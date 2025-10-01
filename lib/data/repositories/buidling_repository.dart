import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:receipts_v2/core/api_helper.dart';
import 'package:receipts_v2/data/dtos/building_dto.dart';
import 'package:receipts_v2/data/models/building.dart';
import 'package:receipts_v2/data/models/room.dart';
import 'package:receipts_v2/data/repositories/auth_repository.dart';
import 'package:receipts_v2/data/repositories/room_repository.dart';

class BuildingRepository {
  final ApiHelper _apiHelper = ApiHelper.instance;
  final Logger _logger = Logger();
  List<Building> _buildingCache = [];

  final RoomRepository _roomRepository;
  final AuthRepository _authRepository;

  BuildingRepository(this._roomRepository, this._authRepository);

  Future<bool> _hasNetwork() => _apiHelper.hasNetwork();

  Future<String?> _getToken() async {
    final token = await _authRepository.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Not authenticated. Please login again.');
    }
    return token;
  }

  Future<List<BuildingDto>> _fetchBuildingDtos() async {
    if (!await _hasNetwork()) {
      throw Exception('No internet connection.');
    }

    final token = await _getToken();
    final url = '${_apiHelper.baseUrl}/buildings';

    try {
      final response = await _apiHelper.dio.get(
        url,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        if (data is List) {
          return data.map((json) => BuildingDto.fromJson(json)).toList();
        }
        throw Exception('Unexpected response format');
      } else {
        throw Exception('Failed to fetch buildings: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Session expired. Please login again.');
      }
      _logger.e('fetchBuildingDtos error: ${e.message}');
      final errorMessage = e.response?.data['message'] ??
          e.response?.data['error'] ??
          'Failed to fetch buildings';
      throw Exception(errorMessage);
    }
  }

  Future<void> load() async {
    try {
      final dtos = await _fetchBuildingDtos();
      _buildingCache = dtos.map((dto) => dto.toBuilding()).toList();
      _logger.i(
          'Buildings loaded successfully: ${_buildingCache.length} buildings');
    } catch (e) {
      _logger.e('Failed to load buildings: $e');
      if (_buildingCache.isEmpty) {
        throw Exception('Failed to load building data: $e');
      }
      rethrow;
    }
  }

  Future<Building> createBuilding(Building newBuilding) async {
    if (!await _hasNetwork()) {
      throw Exception('No internet connection.');
    }

    final token = await _getToken();
    final url = '${_apiHelper.baseUrl}/buildings';

    try {
      final requestBody = {
        'name': newBuilding.name,
        'rentPrice': newBuilding.rentPrice,
        'electricPrice': newBuilding.electricPrice,
        'waterPrice': newBuilding.waterPrice,
      };

      final response = await _apiHelper.dio.post(
        url,
        data: requestBody,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        // Parse response - API wraps in 'data' key
        final responseData = response.data['data'] ?? response.data;
        final buildingDto = BuildingDto.fromJson(responseData);
        final createdBuilding = buildingDto.toBuilding();
        _buildingCache.add(createdBuilding);

        // If newBuilding has rooms, create them
        if (newBuilding.rooms.isNotEmpty) {
          for (Room room in newBuilding.rooms) {
            final roomWithBuildingRef = Room(
              id: room.id,
              roomNumber: room.roomNumber,
              roomStatus: room.roomStatus,
              price: room.price,
              buildingId: createdBuilding.id,
              building: createdBuilding,
              tenant: room.tenant,
            );
            await _roomRepository.createRoom(roomWithBuildingRef);
          }
        }

        _logger.i('Building created successfully');
        return createdBuilding;
      } else if (response.statusCode == 400) {
        final errorMessage = response.data['message'] ??
            response.data['error'] ??
            'Building name is required';
        throw Exception(errorMessage);
      } else if (response.statusCode == 409) {
        final errorMessage = response.data['message'] ??
            response.data['error'] ??
            'Building with this name already exists';
        throw Exception(errorMessage);
      } else {
        throw Exception('Failed to create building');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Session expired. Please login again.');
      }
      if (e.response?.statusCode == 400) {
        final errorMessage = e.response?.data['message'] ??
            e.response?.data['error'] ??
            'Building name is required';
        throw Exception(errorMessage);
      }
      if (e.response?.statusCode == 409) {
        final errorMessage = e.response?.data['message'] ??
            e.response?.data['error'] ??
            'Building with this name already exists';
        throw Exception(errorMessage);
      }
      _logger.e('createBuilding error: ${e.message}');
      final errorMessage = e.response?.data['message'] ??
          e.response?.data['error'] ??
          'Failed to create building';
      throw Exception(errorMessage);
    }
  }

  Future<Building> updateBuilding(Building updatedBuilding) async {
    if (!await _hasNetwork()) {
      throw Exception('No internet connection.');
    }

    final token = await _getToken();
    final url = '${_apiHelper.baseUrl}/buildings/${updatedBuilding.id}';

    try {
      final requestBody = {
        'name': updatedBuilding.name,
        'rentPrice': updatedBuilding.rentPrice,
        'electricPrice': updatedBuilding.electricPrice,
        'waterPrice': updatedBuilding.waterPrice,
      };

      final response = await _apiHelper.dio.put(
        url,
        data: requestBody,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode == 200) {
        final index =
            _buildingCache.indexWhere((b) => b.id == updatedBuilding.id);
        if (index != -1) {
          _buildingCache[index] = updatedBuilding;
        }
        _logger.i('Building updated successfully');
        return updatedBuilding;
      } else if (response.statusCode == 404) {
        throw Exception('Building not found or not authorized');
      } else {
        throw Exception('Failed to update building');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Session expired. Please login again.');
      }
      if (e.response?.statusCode == 404) {
        throw Exception('Building not found or not authorized');
      }
      _logger.e('updateBuilding error: ${e.message}');
      final errorMessage = e.response?.data['message'] ??
          e.response?.data['error'] ??
          'Failed to update building';
      throw Exception(errorMessage);
    }
  }

  Future<void> deleteBuilding(String buildingId) async {
    if (!await _hasNetwork()) {
      throw Exception('No internet connection.');
    }

    final token = await _getToken();
    final url = '${_apiHelper.baseUrl}/buildings/$buildingId';

    try {
      final response = await _apiHelper.dio.delete(
        url,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        // Delete associated rooms from cache
        final buildingToDelete = _buildingCache.firstWhere(
          (b) => b.id == buildingId,
          orElse: () => throw Exception('Building not found in cache'),
        );

        if (buildingToDelete.rooms.isNotEmpty) {
          for (Room room in buildingToDelete.rooms) {
            try {
              await _roomRepository.deleteRoom(room.id);
            } catch (e) {
              _logger.w('Failed to delete room ${room.id}: $e');
            }
          }
        }

        _buildingCache.removeWhere((b) => b.id == buildingId);
        _logger.i('Building deleted successfully');
      } else if (response.statusCode == 404) {
        throw Exception('Building not found or not authorized');
      } else {
        throw Exception('Failed to delete building');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Session expired. Please login again.');
      }
      if (e.response?.statusCode == 404) {
        throw Exception('Building not found or not authorized');
      }
      _logger.e('deleteBuilding error: ${e.message}');
      final errorMessage = e.response?.data['message'] ??
          e.response?.data['error'] ??
          'Failed to delete building';
      throw Exception(errorMessage);
    }
  }

  Future<void> updateRoom(String buildingId, Room room) async {
    final building = _buildingCache.firstWhere(
      (b) => b.id == buildingId,
      orElse: () => throw Exception('Building not found'),
    );

    final roomIndex = building.rooms.indexWhere((r) => r.id == room.id);
    if (roomIndex != -1) {
      building.rooms[roomIndex] = room;
      await _roomRepository.updateRoom(room);
    } else {
      throw Exception('Room not found in building');
    }
  }

  List<Building> getAllBuildings() {
    return List.unmodifiable(_buildingCache);
  }

  Building? getBuildingById(String buildingId) {
    try {
      return _buildingCache.firstWhere((b) => b.id == buildingId);
    } catch (e) {
      return null;
    }
  }

  bool isBuildingEmpty(String buildingId) {
    final building = _buildingCache.firstWhere(
      (b) => b.id == buildingId,
      orElse: () => throw Exception('Building not found'),
    );
    return building.rooms.isEmpty;
  }

  int getBuildingCount() {
    return _buildingCache.length;
  }

  void clearCache() {
    _buildingCache.clear();
    _logger.i('Building cache cleared');
  }

  bool hasData() {
    return _buildingCache.isNotEmpty;
  }
}
