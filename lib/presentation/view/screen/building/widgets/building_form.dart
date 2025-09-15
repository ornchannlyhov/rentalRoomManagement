import 'package:flutter/material.dart';
import 'package:receipts_v2/data/models/building.dart';
import 'package:receipts_v2/data/models/enum/mode.dart';
import 'package:receipts_v2/data/models/room.dart'; 
import 'package:receipts_v2/data/models/enum/room_status.dart'; 
import 'package:receipts_v2/presentation/view/app_widgets/number_field.dart';
import 'package:uuid/uuid.dart'; 

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
      roomQuantity =
          building.rooms.length; 
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

      List<Room> generatedRooms = [];
      if (!isEditing && roomQuantity > 0) {
        for (int i = 1; i <= roomQuantity; i++) {
          generatedRooms.add(
            Room(
              id: const Uuid().v4(),
              roomNumber: i.toString(), 
              roomStatus: RoomStatus.available,
              price: rentPrice, 
              building: Building(
                id: isEditing
                    ? widget.building!.id
                    : DateTime.now()
                        .toString(), 
                name: name,
                rentPrice: rentPrice,
                electricPrice: electricPrice,
                waterPrice: waterPrice,
              ),
            ),
          );
        }
      }

      final newBuilding = Building(
        id: isEditing ? widget.building!.id : DateTime.now().toString(),
        name: name,
        rentPrice: rentPrice,
        electricPrice: electricPrice,
        waterPrice: waterPrice,
        rooms: generatedRooms,
      );

      Navigator.pop(context, newBuilding);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.background,
        iconTheme: theme.iconTheme.copyWith(
          color: theme.iconTheme.color ?? theme.colorScheme.onPrimary,
        ),
        title: Text(
          isEditing ? 'កែប្រែអគារ' : 'បញ្ចូលអគារថ្មី',
          style: TextStyle(color: theme.colorScheme.onSurface)
        ),
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
                initialValue: name,
                decoration: InputDecoration(
                  labelText: 'ឈ្មោះអគារ',
                  labelStyle: theme.textTheme.bodyMedium,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'សូមបញ្ចូលឈ្មោះអគារ។';
                  }
                  return null;
                },
                onSaved: (value) => name = value!,
              ),
              const SizedBox(height: 12),
              NumberTextFormField(
                initialValue: rentPrice.toString(),
                label: 'តម្លៃជួលប្រចាំខែ',
                onSaved: (value) => rentPrice = double.parse(value!),
              ),
              const SizedBox(height: 12),
              if (!isEditing) 
                Column(
                  children: [
                    NumberTextFormField(
                      initialValue: roomQuantity.toString(),
                      label: 'ចំនួនបន្ទប់',
                      onSaved: (value) => roomQuantity = int.parse(value!),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'សូមបញ្ចូលចំនួនបន្ទប់។';
                        }
                        if (int.tryParse(value) == null ||
                            int.parse(value) < 0) {
                          return 'សូមបញ្ចូលចំនួនបន្ទប់ត្រឹមត្រូវ។';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              NumberTextFormField(
                initialValue: electricPrice.toString(),
                label: 'តម្លៃអគ្គិសនី (1kWh)',
                onSaved: (value) => electricPrice = double.parse(value!),
              ),
              const SizedBox(height: 12),
              NumberTextFormField(
                initialValue: waterPrice.toString(),
                label: 'តម្លៃទឹក (1m³)',
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
                      isEditing ? 'រក្សាទុកការកែប្រែ' : 'រក្សាទុកអគារ',
                      style: TextStyle(color: Colors.white),
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
