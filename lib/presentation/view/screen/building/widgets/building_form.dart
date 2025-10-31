import 'package:flutter/material.dart';
import 'package:joul_v2/data/models/building.dart';
import 'package:joul_v2/data/models/enum/mode.dart';
import 'package:joul_v2/data/models/room.dart';
import 'package:joul_v2/data/models/enum/room_status.dart';
import 'package:joul_v2/presentation/view/app_widgets/number_field.dart';
import 'package:uuid/uuid.dart';
import 'package:joul_v2/l10n/app_localizations.dart';   // ← NEW

class BuildingForm extends StatefulWidget {
  final Mode mode;
  final Building? building;
  final List<Building> buildings;

  const BuildingForm({
    super.key,
    this.mode = Mode.creating,
    this.building,
    this.buildings = const [],
  });

  @override
  State<BuildingForm> createState() => _BuildingFormState();
}

class _BuildingFormState extends State<BuildingForm> {
  final _formKey = GlobalKey<FormState>();
  late String id;
  late String name;
  late double rentPrice;
  late double electricPrice;
  late double waterPrice;
  late int roomQuantity;

  bool get isEditing => widget.mode == Mode.editing;

  @override
  void initState() {
    super.initState();
    if (isEditing && widget.building != null) {
      final building = widget.building!;
      id = building.id;
      name = building.name;
      rentPrice = building.rentPrice;
      electricPrice = building.electricPrice;
      waterPrice = building.waterPrice;
      roomQuantity = building.rooms.length;
    } else {
      id = '';
      name = '';
      rentPrice = 0.0;
      electricPrice = 0.0;
      waterPrice = 0.0;
      roomQuantity = 0;
    }
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      List<Room> finalRooms = [];
      final buildingId =
          isEditing ? widget.building!.id : const Uuid().v4();

      final tempBuilding = Building(
        id: buildingId,
        name: name,
        rentPrice: rentPrice,
        electricPrice: electricPrice,
        waterPrice: waterPrice,
        rooms: const [],
      );

      if (isEditing && widget.building != null) {
        finalRooms = widget.building!.rooms.map((room) {
          return Room(
            id: room.id,
            roomNumber: room.roomNumber,
            roomStatus: room.roomStatus,
            price: room.price,
            building: tempBuilding,
            tenant: room.tenant,
          );
        }).toList();
      } else if (!isEditing && roomQuantity > 0) {
        for (int i = 1; i <= roomQuantity; i++) {
          finalRooms.add(
            Room(
              id: const Uuid().v4(),
              roomNumber: i.toString(),
              roomStatus: RoomStatus.available,
              price: rentPrice,
              building: tempBuilding,
              tenant: null,
            ),
          );
        }
      }

      final newBuilding = Building(
        id: buildingId,
        name: name,
        rentPrice: rentPrice,
        electricPrice: electricPrice,
        waterPrice: waterPrice,
        rooms: finalRooms,
      );

      Navigator.pop(context, newBuilding);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;   // ← NEW

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        iconTheme: theme.iconTheme.copyWith(
          color: theme.iconTheme.color ?? theme.colorScheme.onPrimary,
        ),
        title: Text(
          isEditing ? l10n.editBuilding : l10n.addNewBuilding,
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.cancel, color: theme.colorScheme.onSurface),
            tooltip: l10n.cancel,
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
                decoration: InputDecoration(
                  labelText: l10n.buildingName,
                  labelStyle: theme.textTheme.bodyMedium,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.buildingNameRequired;
                  }
                  return null;
                },
                onSaved: (value) => name = value!,
              ),
              const SizedBox(height: 12),
              NumberTextFormField(
                initialValue: rentPrice.toString(),
                label: l10n.rentPriceLabel,
                onSaved: (value) => rentPrice = double.parse(value!),
              ),
              const SizedBox(height: 12),

              NumberTextFormField(
                initialValue: roomQuantity.toString(),
                label: isEditing ? l10n.currentRoomCount : l10n.roomCount,
                enabled: !isEditing,
                onSaved: (value) => roomQuantity = int.parse(value!),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.roomCountRequired;
                  }
                  if (int.tryParse(value) == null || int.parse(value) < 0) {
                    return l10n.roomCountInvalid;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              if (isEditing)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.roomCountEditNote,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              NumberTextFormField(
                initialValue: electricPrice.toString(),
label: l10n.electricPricePerKwh,
                onSaved: (value) => electricPrice = double.parse(value!),
              ),
              const SizedBox(height: 12),
              NumberTextFormField(
                initialValue: waterPrice.toString(),
                label: l10n.waterPricePerCubicMeter,
                onSaved: (value) => waterPrice = double.parse(value!),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                    ),
                    onPressed: _save,
                    child: Text(
                      isEditing ? l10n.saveChanges : l10n.saveBuilding,
                      style: const TextStyle(color: Colors.white),
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