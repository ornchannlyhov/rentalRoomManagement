import 'package:flutter/material.dart';
import 'package:receipts_v2/model/building.dart';
import 'package:receipts_v2/model/enum/mode.dart';
import 'package:receipts_v2/model/enum/room_status.dart';
import 'package:receipts_v2/model/room.dart';
import 'package:receipts_v2/model/service.dart';
import 'package:receipts_v2/repository/buidling_repository.dart';
import 'package:receipts_v2/repository/room_repository.dart';
import 'package:receipts_v2/repository/service_repository.dart';
import 'package:receipts_v2/view/widget/buildingWidgets/building_card.dart';
import 'package:receipts_v2/view/widget/buildingWidgets/switch_button.dart';
import 'package:receipts_v2/view/widget/roomWidget/room_card.dart';
import 'package:receipts_v2/view/widget/roomWidget/room_form.dart';
import 'package:receipts_v2/view/widget/serviceWidget/service_card.dart';
import 'package:receipts_v2/view/widget/serviceWidget/service_form.dart';

class BuildingDetail extends StatefulWidget {
  final Building building;
  final List<Service> services;
  const BuildingDetail(
      {super.key, required this.building, required this.services});
  @override
  State<BuildingDetail> createState() => _BuildingDetailState();
}

class _BuildingDetailState extends State<BuildingDetail> {
  ScreenType _currentScreen = ScreenType.room;

  List<Building> buildings = [];
  List<Service> services = [];
  List<Room> rooms = [];

  final buildingRepository = BuildingRepository();
  final roomRepository = RoomRepository();
  final serviceRepository = ServiceRepository();

  @override
  void initState() {
    super.initState();
    _loadServiceAndRoom();
  }

  Future<void> _loadServiceAndRoom() async {
    await buildingRepository.load();
    await serviceRepository.load();
    await roomRepository.load();
    setState(() {
      buildings = buildingRepository.getAllBuildings();
      services = serviceRepository.getAllServices();
      rooms = roomRepository.getAllRooms();
    });
    print(rooms.length);
  }

  Future<void> _addRoom(BuildContext context) async {
    final newRoom = await Navigator.of(context).push<Room>(
      MaterialPageRoute(
        builder: (ctx) => RoomForm(
          building: widget.building,
        ),
      ),
    );

    if (newRoom != null) {
      setState(() {
        roomRepository.createRoom(newRoom);
        buildingRepository.addRoom(widget.building.id, newRoom);
        rooms.add(newRoom);
        _loadServiceAndRoom();
      });
    }
  }

  Future<void> _editRoom(BuildContext context, Room room) async {
    final updatedRoom = await Navigator.of(context).push<Room>(
      MaterialPageRoute(
        builder: (ctx) => RoomForm(
          building: widget.building,
          mode: Mode.editing,
          room: room,
        ),
      ),
    );

    if (updatedRoom != null) {
      setState(() {
        roomRepository.updateRoom(updatedRoom);
        final index = rooms.indexWhere((r) => r.id == updatedRoom.id);
        if (index != -1) {
          rooms[index] = updatedRoom;
          _loadServiceAndRoom();
        }
      });
    }
  }

  Future<void> _addService(BuildContext context) async {
    final newService = await Navigator.of(context).push<Service>(
      MaterialPageRoute(
        builder: (ctx) => ServiceForm(
          building: widget.building,
        ),
      ),
    );

    if (newService != null) {
      setState(() {
        serviceRepository.createService(newService);
        services.add(newService);
        _loadServiceAndRoom();
      });
    }
  }

  Future<void> _editService(BuildContext context, Service service) async {
    final updatedService = await Navigator.of(context).push<Service>(
      MaterialPageRoute(
        builder: (ctx) => ServiceForm(
          building: widget.building,
          mode: Mode.editing,
          service: service,
        ),
      ),
    );

    if (updatedService != null) {
      setState(() {
        serviceRepository.updateService(updatedService);
        final index = services.indexWhere((s) => s.id == updatedService.id);
        if (index != -1) {
          services[index] = updatedService;
          _loadServiceAndRoom();
        }
      });
    }
  }

  void _deleteRoom(BuildContext context, int index, Room room) {
    roomRepository.deleteRoom(room.id);
    setState(() {
      rooms.removeAt(index);
    });
    final removedRoom = room;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 3),
        content: Text('Room "${room.roomNumber}" deleted'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            roomRepository.restoreRoom(index, removedRoom);
            setState(() {
              rooms.insert(index, removedRoom);
            });
          },
        ),
      ),
    );
    print(rooms.length);
    print(rooms.where((room) => room.roomStatus == RoomStatus.occupied).length);
    _loadServiceAndRoom();
  }

  void _deleteService(BuildContext context, int index, Service service) {
    serviceRepository.deleteService(service.id);
    setState(() {
      services.removeAt(index);
    });
    final removedService = service;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 3),
        content: Text('Service "${service.name}" deleted'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            serviceRepository.restoreService(index, removedService);
            setState(() {
              services.insert(index, removedService);
            });
          },
        ),
      ),
    );
    _loadServiceAndRoom();
  }

  Widget _buildRoomContent() {
    if (rooms.isEmpty) {
      return const Center(
        child: Text(
          'No rooms available',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
      );
    }
    return ListView.builder(
      itemCount: rooms.length,
      itemBuilder: (context, index) {
        final room = rooms[index];
        return Dismissible(
          key: Key(room.id),
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          direction: DismissDirection.endToStart,
          onDismissed: (_) => _deleteRoom(context, index, room),
          child: RoomCard(
            room: room,
            status: room.roomStatus == RoomStatus.occupied,
            onTap: () {
              _editRoom(context, room);
            },
          ),
        );
      },
    );
  }

  Widget _buildServiceContent() {
    if (services.isEmpty) {
      return const Center(
        child: Text(
          'No services available',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
      );
    }
    return ListView.builder(
      itemCount: services.length,
      itemBuilder: (context, index) {
        final service = services[index];
        return Dismissible(
          key: Key(service.id),
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          direction: DismissDirection.endToStart,
          onDismissed: (_) => _deleteService(context, index, service),
          child: ServiceCard(
            service: service,
            onTap: () {
              _editService(context, service);
            },
          ),
        );
      },
    );
  }

  Widget _buildScreenHeader() {
    String headerTitle = '';
    Widget actionButton;

    switch (_currentScreen) {
      case ScreenType.room:
        headerTitle = 'Rooms';
        actionButton = IconButton(
          icon: const Icon(Icons.add),
          onPressed: () {
            _addRoom(context);
          },
        );
        break;
      case ScreenType.service:
        headerTitle = 'Services';
        actionButton = IconButton(
          icon: const Icon(Icons.add),
          onPressed: () {
            _addService(context);
          },
        );
        break;
      default:
        headerTitle = '';
        actionButton = const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Text(
              headerTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          actionButton,
        ],
      ),
    );
  }

  Widget _buildScreenContent() {
    switch (_currentScreen) {
      case ScreenType.room:
        return _buildRoomContent();
      case ScreenType.service:
        return _buildServiceContent();
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.building.name),
        backgroundColor: const Color(0xFF1A0C2D),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
            child: BuildingCard(
              building: widget.building,
              onTap: () {},
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: ScreenSwitchButton(
              onScreenSelected: (screen) {
                setState(() {
                  _currentScreen = screen;
                });
              },
            ),
          ),
          _buildScreenHeader(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _buildScreenContent(),
            ),
          ),
        ],
      ),
    );
  }
}
