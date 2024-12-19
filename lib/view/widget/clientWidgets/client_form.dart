import 'package:flutter/material.dart';
import 'package:receipts_v2/model/enum/gender.dart';
import 'package:receipts_v2/model/room.dart';
import 'package:receipts_v2/model/client.dart';
import 'package:receipts_v2/model/enum/mode.dart';
import 'package:receipts_v2/repository/room_repository.dart';

class ClientForm extends StatefulWidget {
  final Mode mode;
  final Client? client;

  const ClientForm({
    super.key,
    this.mode = Mode.creating,
    this.client,
  });

  @override
  State<ClientForm> createState() => _ClientFormState();
}

class _ClientFormState extends State<ClientForm> {
  final _formKey = GlobalKey<FormState>();
  final roomRepository = RoomRepository();

  List<Room> availableRooms = [];
  List<Room> rooms = [];

  late String id;
  late String name;
  late String phoneNumber;
  Room? selectedRoom;
  late Gender gender;

  bool get isEditing => widget.mode == Mode.editing;

  @override
  void initState() {
    super.initState();
    _loadRoom();
    if (isEditing && widget.client != null) {
      final client = widget.client!;
      id = client.id;
      name = client.name;
      phoneNumber = client.phoneNumber;
      selectedRoom = client.room;
      gender = client.gender;
    } else {
      id = '';
      name = '';
      phoneNumber = '';
      selectedRoom = null;
      gender = Gender.male;
    }
  }

  Future<void> _loadRoom() async {
    try {
      await roomRepository.load();
      setState(() {
        availableRooms = roomRepository.getAvailableRooms();
        rooms = roomRepository.getAllRooms();
        selectedRoom = isEditing && widget.client?.room != null
            ? rooms.firstWhere(
                (room) => room.id == widget.client!.room!.id,
                orElse: () => rooms.first,
              )
            : null;
        if (selectedRoom != null &&
            !availableRooms.any((room) => room.id == selectedRoom!.id)) {
          availableRooms.add(selectedRoom!);
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load rooms: $e')),
      );
    }
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final newClient = Client(
        id: isEditing ? widget.client!.id : DateTime.now().toString(),
        name: name,
        phoneNumber: phoneNumber,
        room: selectedRoom,
        gender: gender,
      );
      Navigator.pop(context, newClient);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Client' : 'Create New Client'),
        actions: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.cancel),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                initialValue: name,
                decoration: const InputDecoration(labelText: 'Client Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a client name.';
                  }
                  return null;
                },
                onSaved: (value) => name = value!,
              ),
              TextFormField(
                initialValue: phoneNumber,
                decoration: const InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a phone number.';
                  }
                  return null;
                },
                onSaved: (value) => phoneNumber = value!,
              ),
              DropdownButtonFormField<Room>(
                value: selectedRoom,
                items: availableRooms.map((room) {
                  return DropdownMenuItem(
                    value: room,
                    child: Text('Room: ${room.roomNumber}'),
                  );
                }).toList(),
                onChanged: (value) async {
                  if (value != null) {
                    setState(() {
                      selectedRoom = value;
                    });
                  }
                },
                decoration: const InputDecoration(labelText: 'Room'),
                validator: (value) =>
                    value == null ? 'Please select a room' : null,
              ),
              DropdownButtonFormField<Gender>(
                value: gender,
                decoration: const InputDecoration(labelText: 'Gender'),
                items: Gender.values
                    .map((g) => DropdownMenuItem(
                          value: g,
                          child: Text(g.name),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => gender = value!),
                onSaved: (value) => gender = value!,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: _save,
                    child: Text(isEditing ? 'Update Client' : 'Create Client'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
