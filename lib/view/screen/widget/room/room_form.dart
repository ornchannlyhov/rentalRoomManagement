import 'package:flutter/material.dart';
import 'package:receipts_v2/model/building.dart';
import 'package:receipts_v2/model/enum/mode.dart';
import 'package:receipts_v2/model/enum/room_status.dart';
import 'package:receipts_v2/model/room.dart';
import 'package:receipts_v2/view/appComponent/number_field.dart';
import 'package:uuid/uuid.dart';

class RoomForm extends StatefulWidget {
  final Room? room;
  final Mode mode;
  final Building building;

  const RoomForm({
    super.key,
    this.room,
    this.mode = Mode.creating,
    required this.building,
  });

  @override
  State<RoomForm> createState() => _RoomFormState();
}

class _RoomFormState extends State<RoomForm> {
  final _formKey = GlobalKey<FormState>();
  late String roomNumber;
  late Building? selectedBuilding;
  late double price;
  late RoomStatus roomStatus;

  bool get isEditing => widget.mode == Mode.editing;

  @override
  void initState() {
    super.initState();
    if (isEditing && widget.room != null) {
      final room = widget.room!;
      roomNumber = room.roomNumber;
      selectedBuilding = room.building;
      price = room.price;
      roomStatus = room.roomStatus;
    } else {
      roomNumber = '';
      selectedBuilding =
      widget.building;
      price = selectedBuilding?.rentPrice ?? 0.0;
      roomStatus = RoomStatus.available;
    }
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final newRoom = Room(
        id: isEditing ? widget.room!.id : const Uuid().v4(),
        roomNumber: roomNumber,
        roomStatus: roomStatus,
        price: price,
        building: selectedBuilding,
      );

      Navigator.pop(context, newRoom);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Room' : 'Create New Room'),
        actions: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.cancel),
          ),
        ],
        backgroundColor: const Color.fromARGB(255, 18, 13, 29),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                initialValue: roomNumber,
                decoration: const InputDecoration(labelText: 'Room Number'),
                onSaved: (value) => roomNumber = value!,
                validator: (value) =>
                    value!.isEmpty ? 'Please enter a room number' : null,
              ),
              NumberTextFormField(
                initialValue: price.toString(),
                label: 'Room Price',
                onSaved: (value) => price = double.parse(value!),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: _save,
                    child: const Text('Save Room'),
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
