import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:receipts_v2/core/api_helper.dart';
import 'package:receipts_v2/data/dtos/room_dto.dart';
import 'package:receipts_v2/data/models/enum/room_status.dart';
import 'package:receipts_v2/data/models/room.dart';
import 'package:receipts_v2/data/models/tenant.dart';
import 'package:receipts_v2/data/repositories/auth_repository.dart';

class RoomRepository {
  final ApiHelper _apiHelper = ApiHelper.instance;
  final Logger _logger = Logger();
  final AuthRepository _authRepository;

  List<Room> _roomCache = [];

  RoomRepository(this._authRepository);

  Future<bool> _hasNetwork() => _apiHelper.hasNetwork();

  Future<String?> _getToken() async {
    final token = await _authRepository.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Not authenticated. Please login again.');
    }
    return token;
  }

  Future<List<RoomDto>> _fetchRoomDtos() async {
    if (!await _hasNetwork()) {
      throw Exception('No internet connection.');
    }

    final token = await _getToken();
    final url = '${_apiHelper.baseUrl}/rooms';

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
          return data.map((json) => RoomDto.fromJson(json)).toList();
        }
        throw Exception('Unexpected response format');
      } else {
        throw Exception('Failed to fetch rooms: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Session expired. Please login again.');
      }
      _logger.e('fetchRoomDtos error: ${e.message}');
      final errorMessage = e.response?.data['message'] ??
          e.response?.data['error'] ??
          'Failed to fetch rooms';
      throw Exception(errorMessage);
    }
  }

  Future<void> load() async {
    try {
      final dtos = await _fetchRoomDtos();
      _roomCache = dtos.map((dto) => dto.toRoom()).toList();
      _logger.i('Rooms loaded successfully: ${_roomCache.length} rooms');
    } catch (e) {
      _logger.e('Failed to load rooms: $e');
      if (_roomCache.isEmpty) {
        throw Exception('Failed to load room data: $e');
      }
      rethrow;
    }
  }

  Future<Room> createRoom(Room newRoom) async {
    if (!await _hasNetwork()) {
      throw Exception('No internet connection.');
    }

    final token = await _getToken();
    final url = '${_apiHelper.baseUrl}/rooms';

    try {
      final requestBody = {
        'buildingId': newRoom.building!.id,
        'roomNumber': newRoom.roomNumber,
        'price': newRoom.price,
        'roomStatus': newRoom.roomStatus.name,
        if (newRoom.tenant != null) 'tenantChatId': 0, // Add if needed
      };

      final response = await _apiHelper.dio.post(
        url,
        data: requestBody,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final roomDto =
            RoomDto.fromJson(response.data['data'] ?? response.data);
        final createdRoom = roomDto.toRoom();
        _roomCache.add(createdRoom);
        _logger.i('Room created successfully');
        return createdRoom;
      } else {
        throw Exception('Failed to create room: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Session expired. Please login again.');
      }
      if (e.response?.statusCode == 403) {
        throw Exception('Building not found or not authorized');
      }
      _logger.e('createRoom error: ${e.message}');
      final errorMessage = e.response?.data['message'] ??
          e.response?.data['error'] ??
          'Failed to create room';
      throw Exception(errorMessage);
    }
  }

  Future<Room> updateRoom(Room updatedRoom) async {
    if (!await _hasNetwork()) {
      throw Exception('No internet connection.');
    }

    final token = await _getToken();
    final url = '${_apiHelper.baseUrl}/rooms/${updatedRoom.id}';

    try {
      final requestBody = {
        'roomNumber': updatedRoom.roomNumber,
        'price': updatedRoom.price,
        'roomStatus': updatedRoom.roomStatus.name,
        if (updatedRoom.tenant != null) 'tenantChatId': 0, // Add if needed
      };

      final response = await _apiHelper.dio.put(
        url,
        data: requestBody,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode == 200) {
        final index = _roomCache.indexWhere((r) => r.id == updatedRoom.id);
        if (index != -1) {
          _roomCache[index] = updatedRoom;
        }
        _logger.i('Room updated successfully');
        return updatedRoom;
      } else if (response.statusCode == 400) {
        throw Exception('No changes detected');
      } else {
        throw Exception('Failed to update room: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Session expired. Please login again.');
      }
      if (e.response?.statusCode == 404) {
        throw Exception('Room not found or not authorized');
      }
      if (e.response?.statusCode == 400) {
        throw Exception('No changes detected');
      }
      _logger.e('updateRoom error: ${e.message}');
      final errorMessage = e.response?.data['message'] ??
          e.response?.data['error'] ??
          'Failed to update room';
      throw Exception(errorMessage);
    }
  }

  Future<void> deleteRoom(String roomId) async {
    if (!await _hasNetwork()) {
      throw Exception('No internet connection.');
    }

    final token = await _getToken();
    final url = '${_apiHelper.baseUrl}/rooms/$roomId';

    try {
      final response = await _apiHelper.dio.delete(
        url,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        _roomCache.removeWhere((r) => r.id == roomId);
        _logger.i('Room deleted successfully');
      } else {
        throw Exception('Failed to delete room: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Session expired. Please login again.');
      }
      if (e.response?.statusCode == 404) {
        throw Exception('Room not found or not authorized');
      }
      _logger.e('deleteRoom error: ${e.message}');
      final errorMessage = e.response?.data['message'] ??
          e.response?.data['error'] ??
          'Failed to delete room';
      throw Exception(errorMessage);
    }
  }

  Future<void> updateRoomStatus(String roomId, RoomStatus status) async {
    final room = _roomCache.firstWhere(
      (r) => r.id == roomId,
      orElse: () => throw Exception('Room not found'),
    );
    final updatedRoom = Room(
      id: room.id,
      roomNumber: room.roomNumber,
      roomStatus: status,
      price: room.price,
      buildingId: room.buildingId,
      building: room.building,
      tenant: room.tenant,
    );
    await updateRoom(updatedRoom);
  }

  Future<void> addTenant(String roomId, Tenant tenant) async {
    final room = _roomCache.firstWhere(
      (r) => r.id == roomId,
      orElse: () => throw Exception('Room not found'),
    );
    room.tenant = tenant;
    await updateRoom(room);
  }

  Future<void> removeTenant(String roomId) async {
    final room = _roomCache.firstWhere(
      (r) => r.id == roomId,
      orElse: () => throw Exception('Room not found'),
    );
    room.tenant = null;
    await updateRoom(room);
  }

  List<Room> getAllRooms() {
    return List.unmodifiable(_roomCache);
  }

  List<Room> getAvailableRooms() {
    return _roomCache
        .where((room) => room.roomStatus == RoomStatus.available)
        .toList();
  }

  List<Room> getThisBuildingRooms(String buildingId) {
    return _roomCache.where((room) => room.building?.id == buildingId).toList();
  }

  Room? getRoomById(String roomId) {
    try {
      return _roomCache.firstWhere((r) => r.id == roomId);
    } catch (e) {
      return null;
    }
  }

  int getRoomCount() {
    return _roomCache.length;
  }

  void clearCache() {
    _roomCache.clear();
    _logger.i('Room cache cleared');
  }

  bool hasData() {
    return _roomCache.isNotEmpty;
  }
}
