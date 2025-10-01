import 'package:flutter/material.dart';
import 'package:receipts_v2/data/models/building.dart';
import 'package:receipts_v2/data/models/enum/mode.dart';
import 'package:receipts_v2/data/models/enum/room_status.dart';
import 'package:receipts_v2/data/models/room.dart';
import 'package:receipts_v2/presentation/view/app_widgets/number_field.dart';
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
      selectedBuilding = widget.building;
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
        buildingId: selectedBuilding!.id,
        price: price,
        building: selectedBuilding,
      );
      Navigator.pop(context, newRoom);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor:
            theme.colorScheme.background,
      appBar: AppBar(
        backgroundColor:
            theme.colorScheme.background,
        iconTheme: theme.iconTheme.copyWith(
          color: theme.iconTheme.color ?? theme.colorScheme.onPrimary,
        ),
        title: Text(
          isEditing ? 'កែប្រែបន្ទប់' : 'បន្ថែមបន្ទប់ថ្មី',
          style: theme.appBarTheme.titleTextStyle ??
              theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
        ),
        elevation: theme.appBarTheme.elevation ?? 0,
        shadowColor: theme.appBarTheme.shadowColor,
        actions: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.cancel, color: theme.colorScheme.onSurface),
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
                initialValue: roomNumber,
                decoration: InputDecoration(
                  labelText: 'លេខបន្ទប់',
                  labelStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: theme.colorScheme.outline),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: theme.colorScheme.primary),
                  ),
                ),
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
                onSaved: (value) => roomNumber = value!,
                validator: (value) =>
                    value!.isEmpty ? 'សូមបញ្ចូលលេខបន្ទប់' : null,
              ),
              const SizedBox(height: 16),
              NumberTextFormField(
                initialValue: price.toString(),
                label: 'តម្លៃជួលបន្ទប់',
                onSaved: (value) => price = double.parse(value!),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    onPressed: _save,
                    icon: Icon(
                      Icons.save,
                      color: Colors.white,
                    ),
                    label: Text(
                      'រក្សាទុក',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                    ),
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
