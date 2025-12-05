import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:joul_v2/data/models/building.dart';
import 'package:joul_v2/data/models/enum/mode.dart';
import 'package:joul_v2/data/models/room.dart';
import 'package:joul_v2/data/models/enum/room_status.dart';
import 'package:joul_v2/presentation/view/app_widgets/number_field.dart';
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

  late TextEditingController _nameController;
  late TextEditingController _rentPriceController;
  late TextEditingController _electricPriceController;
  late TextEditingController _waterPriceController;
  late TextEditingController _roomQuantityController;

  // Changed to match model: Single optional string
  String? buildingImagePath;

  bool get isEditing => widget.mode == Mode.editing;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController();
    _rentPriceController = TextEditingController();
    _electricPriceController = TextEditingController();
    _waterPriceController = TextEditingController();
    _roomQuantityController = TextEditingController();

    buildingImagePath = null;

    if (isEditing && widget.building != null) {
      final building = widget.building!;
      _nameController.text = building.name;
      _rentPriceController.text = building.rentPrice.toString();
      _electricPriceController.text = building.electricPrice.toString();
      _waterPriceController.text = building.waterPrice.toString();
      _roomQuantityController.text = building.rooms.length.toString();

      if (building.buildingImage != null &&
          building.buildingImage!.isNotEmpty) {
        buildingImagePath = building.buildingImage;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _rentPriceController.dispose();
    _electricPriceController.dispose();
    _waterPriceController.dispose();
    _roomQuantityController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text;
      final rentPrice = double.tryParse(_rentPriceController.text) ?? 0.0;
      final electricPrice =
          double.tryParse(_electricPriceController.text) ?? 0.0;
      final waterPrice = double.tryParse(_waterPriceController.text) ?? 0.0;
      final roomQuantity = int.tryParse(_roomQuantityController.text) ?? 0;

      File? imageFile;

      if (buildingImagePath != null) {
        if (!buildingImagePath!.startsWith('http')) {
          imageFile = File(buildingImagePath!);
        }
      }

      List<Room> finalRooms = [];
      final buildingId = isEditing ? widget.building!.id : const Uuid().v4();

      final tempBuilding = Building(
        id: buildingId,
        appUserId: widget.building?.appUserId ?? '',
        name: name,
        rentPrice: rentPrice,
        electricPrice: electricPrice,
        waterPrice: waterPrice,
        buildingImage: buildingImagePath,
        services: widget.building?.services ?? [],
        rooms: const [],
        imageFile: imageFile,
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
        buildingImage: buildingImagePath,
        services: widget.building?.services ?? [],
        rooms: finalRooms,
        imageFile: imageFile,
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
          buildingImagePath = image.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context)!
                  .failedToPickImage(e.toString()))),
        );
      }
    }
  }

  void _removeImage() {
    setState(() {
      buildingImagePath = null;
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
              TextFormField(
                controller: _nameController,
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
              ),
              const SizedBox(height: 16),
              NumberTextFormField(
                controller: _rentPriceController,
                label: l10n.rentPriceLabel,
              ),
              const SizedBox(height: 16),
              NumberTextFormField(
                controller: _roomQuantityController,
                label: isEditing ? l10n.currentRoomCount : l10n.roomCount,
                enabled: !isEditing,
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
                    color: theme.colorScheme.surfaceContainerHighest
                        .withOpacity(0.5),
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
              NumberTextFormField(
                controller: _electricPriceController,
                label: l10n.electricPricePerKwh,
              ),
              const SizedBox(height: 16),
              NumberTextFormField(
                controller: _waterPriceController,
                label: l10n.waterPricePerCubicMeter,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.buildingImage,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),

              if (buildingImagePath != null)
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: buildingImagePath!.startsWith('http')
                          ? Image.network(
                              buildingImagePath!,
                              width: double.infinity,
                              height: 200,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: double.infinity,
                                  height: 200,
                                  color:
                                      theme.colorScheme.surfaceContainerHighest,
                                  child:
                                      const Icon(Icons.broken_image, size: 50),
                                );
                              },
                            )
                          : Image.file(
                              File(buildingImagePath!),
                              width: double.infinity,
                              height: 200,
                              fit: BoxFit.cover,
                            ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black54,
                          padding: const EdgeInsets.all(8),
                        ),
                        onPressed: _removeImage,
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 8),

              // Pick/Replace image button
              OutlinedButton.icon(
                onPressed: _pickImage,
                icon: Icon(buildingImagePath == null
                    ? Icons.add_photo_alternate
                    : Icons.edit),
                label: Text(
                  buildingImagePath == null
                      ? l10n.addBuildingImage
                      : l10n.replaceImage,
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: theme.colorScheme.primary),
                ),
              ),

              const SizedBox(height: 24),
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
