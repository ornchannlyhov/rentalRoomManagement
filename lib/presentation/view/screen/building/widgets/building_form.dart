import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:joul_v2/data/models/building.dart';
import 'package:joul_v2/data/models/enum/mode.dart';
import 'package:joul_v2/data/models/room.dart';
import 'package:joul_v2/data/models/enum/room_status.dart';
import 'package:joul_v2/presentation/view/app_widgets/number_field.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import 'package:joul_v2/l10n/app_localizations.dart';

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
  final ImagePicker _picker = ImagePicker();
  late String id;
  late String name;
  late double rentPrice;
  late double electricPrice;
  late double waterPrice;
  late int roomQuantity;
  late String? passKey;
  late List<String> buildingImages;

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
      passKey = building.passKey;
      buildingImages = List.from(building.buildingImages);
    } else {
      id = '';
      name = '';
      rentPrice = 0.0;
      electricPrice = 0.0;
      waterPrice = 0.0;
      roomQuantity = 0;
      passKey = null;
      buildingImages = [];
    }
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      List<Room> finalRooms = [];
      final buildingId = isEditing ? widget.building!.id : const Uuid().v4();

      final tempBuilding = Building(
        id: buildingId,
        appUserId: widget.building?.appUserId ?? '',
        name: name,
        rentPrice: rentPrice,
        electricPrice: electricPrice,
        waterPrice: waterPrice,
        buildingImages: buildingImages,
        services: widget.building?.services ?? [],
        createdAt: widget.building?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        passKey: passKey,
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
        appUserId: widget.building?.appUserId ?? '',
        name: name,
        rentPrice: rentPrice,
        electricPrice: electricPrice,
        waterPrice: waterPrice,
        buildingImages: buildingImages,
        services: widget.building?.services ?? [],
        createdAt: widget.building?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        passKey: passKey,
        rooms: finalRooms,
      );

      Navigator.pop(context, newBuilding);
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          // In production, you'd upload to server and get URL back
          buildingImages.add(image.path); // Temporarily store local path
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      buildingImages.removeAt(index);
    });
  }
  

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

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
              // Building Name
              TextFormField(
                initialValue: name,
                decoration: InputDecoration(
                  labelText: l10n.buildingName,
                  labelStyle: theme.textTheme.bodyMedium,
                  prefixIcon: const Icon(Icons.apartment),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.buildingNameRequired;
                  }
                  return null;
                },
                onSaved: (value) => name = value!,
              ),
              const SizedBox(height: 16),

              // Rent Price
              NumberTextFormField(
                initialValue: rentPrice.toString(),
                label: l10n.rentPriceLabel,
                onSaved: (value) => rentPrice = double.parse(value!),
              ),
              const SizedBox(height: 16),

              // Room Quantity
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

              if (isEditing)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(top: 8, bottom: 12),
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

              const SizedBox(height: 4),

              // Electric Price
              NumberTextFormField(
                initialValue: electricPrice.toString(),
                label: l10n.electricPricePerKwh,
                onSaved: (value) => electricPrice = double.parse(value!),
              ),
              const SizedBox(height: 16),

              // Water Price
              NumberTextFormField(
                initialValue: waterPrice.toString(),
                label: l10n.waterPricePerCubicMeter,
                onSaved: (value) => waterPrice = double.parse(value!),
              ),
              const SizedBox(height: 16),

             
              TextFormField(
                initialValue: passKey,
                decoration: InputDecoration(
                  labelText: 'Passkey (Optional)', 
                  labelStyle: theme.textTheme.bodyMedium,
                  prefixIcon: const Icon(Icons.lock_outline),
                  helperText: 'Used for secure building access',
                ),
                obscureText: true,
                onSaved: (value) => passKey = value?.isEmpty ?? true ? null : value,
              ),
              const SizedBox(height: 16),

            
              Text(
                'Building Images', // Add to l10n: l10n.buildingImages
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              
              if (buildingImages.isNotEmpty)
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: buildingImages.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                buildingImages[index],
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 120,
                                    height: 120,
                                    color: theme.colorScheme.surfaceContainerHighest,
                                    child: const Icon(Icons.broken_image),
                                  );
                                },
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: IconButton(
                                icon: const Icon(Icons.close, color: Colors.white),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.black54,
                                  padding: const EdgeInsets.all(4),
                                ),
                                onPressed: () => _removeImage(index),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              
              const SizedBox(height: 8),
              
              OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.add_photo_alternate),
                label: Text(
                  buildingImages.isEmpty 
                    ? 'Add Building Images' // Add to l10n
                    : 'Add More Images', // Add to l10n
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: theme.colorScheme.primary),
                ),
              ),
              const SizedBox(height: 24),
              

              // Save Button
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
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