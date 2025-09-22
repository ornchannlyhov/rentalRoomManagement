// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:receipts_v2/data/models/enum/gender.dart';
import 'package:receipts_v2/data/models/room.dart';
import 'package:receipts_v2/data/models/tenant.dart';
import 'package:receipts_v2/data/models/enum/mode.dart';
import 'package:receipts_v2/data/repositories/room_repository.dart';
import 'package:receipts_v2/presentation/providers/building_provider.dart';

class TenantForm extends StatefulWidget {
  final Mode mode;
  final Tenant? tenant;
  final String? selectedBuildingId;

  const TenantForm({
    super.key,
    this.mode = Mode.creating,
    this.tenant,
    this.selectedBuildingId,
  });

  @override
  State<TenantForm> createState() => _TenantFormState();
}

class _TenantFormState extends State<TenantForm> {
  final _formKey = GlobalKey<FormState>();
  final roomRepository = RoomRepository();

  List<Room> availableRooms = [];
  List<Room> rooms = [];

  late String id;
  late String name;
  late String phoneNumber;
  String? selectedRoomId; // Changed to use room ID instead of Room object
  late Gender gender;
  String? selectedBuildingId;

  bool get isEditing => widget.mode == Mode.editing;

  @override
  void initState() {
    super.initState();
    selectedBuildingId = widget.selectedBuildingId;
    _loadRoom();
    if (isEditing && widget.tenant != null) {
      final tenant = widget.tenant!;
      id = tenant.id;
      name = tenant.name;
      phoneNumber = tenant.phoneNumber;
      selectedRoomId = tenant.room?.id; // Use room ID
      gender = tenant.gender;
      if (tenant.room?.building != null) {
        selectedBuildingId = tenant.room!.building!.id;
      }
    } else {
      id = '';
      name = '';
      phoneNumber = '';
      selectedRoomId = null; // Use room ID
      gender = Gender.male;
    }
  }

  Future<void> _loadRoom() async {
    try {
      await roomRepository.load();
      setState(() {
        rooms = roomRepository.getAllRooms();
        availableRooms = roomRepository.getAvailableRooms();

        // Include the current room in availableRooms if editing
        if (isEditing && widget.tenant?.room != null) {
          final currentRoom = rooms.firstWhere(
            (room) => room.id == widget.tenant!.room!.id,
            orElse: () => widget.tenant!.room!,
          );
          if (!availableRooms.any((room) => room.id == currentRoom.id)) {
            availableRooms.add(currentRoom);
          }
        }

        // Filter rooms by selected building if provided
        _filterRoomsByBuilding();

        // Ensure selectedRoomId is valid for the current building filter
        if (selectedRoomId != null &&
            selectedBuildingId != null &&
            !availableRooms.any((room) =>
                room.id == selectedRoomId &&
                room.building?.id == selectedBuildingId)) {
          selectedRoomId = null;
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('បរាជ័យក្នុងការផ្ទុកបន្ទប់: $e')),
        );
      }
    }
  }

  void _filterRoomsByBuilding() {
    if (selectedBuildingId != null) {
      availableRooms = availableRooms
          .where((room) => room.building?.id == selectedBuildingId)
          .toList();
    } else {
      // If no building is selected, show all available rooms
      availableRooms = roomRepository.getAvailableRooms();

      // Include current room if editing
      if (isEditing && widget.tenant?.room != null) {
        final currentRoom = rooms.firstWhere(
          (room) => room.id == widget.tenant!.room!.id,
          orElse: () => widget.tenant!.room!,
        );
        if (!availableRooms.any((room) => room.id == currentRoom.id)) {
          availableRooms.add(currentRoom);
        }
      }
    }
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // Find the selected room object from the ID
      Room? selectedRoom;
      if (selectedRoomId != null) {
        selectedRoom = rooms.firstWhere(
          (room) => room.id == selectedRoomId,
          orElse: () => availableRooms.firstWhere(
            (room) => room.id == selectedRoomId,
          ),
        );
      }

      final newTenant = Tenant(
        id: isEditing ? widget.tenant!.id : DateTime.now().toString(),
        name: name,
        phoneNumber: phoneNumber,
        room: selectedRoom,
        gender: gender,
      );
      Navigator.pop(context, newTenant);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const fieldSpacing = SizedBox(height: 12);
    final buildingProvider = context.watch<BuildingProvider>();

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        title: Text(isEditing ? 'កែប្រែអ្នកជួល' : 'បង្កើតអ្នកជួលថ្មី'),
        actions: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.cancel),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: buildingProvider.buildings.when(
          success: (buildings) {
            return Form(
              key: _formKey,
              child: ListView(
                children: [
                  // Building Filter
                  DropdownButtonFormField<String?>(
                    value: selectedBuildingId,
                    items: [
                      DropdownMenuItem(
                        value: null,
                        child: Text(
                          'ទាំងអស់',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      ...buildings.map((building) => DropdownMenuItem(
                            value: building.id,
                            child: Text(
                              building.name,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          )),
                    ],
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedBuildingId = newValue;
                        // Re-filter rooms based on selected building
                        _filterRoomsByBuilding();

                        // Clear room selection if it doesn't match the new building
                        if (selectedRoomId != null &&
                            !availableRooms
                                .any((room) => room.id == selectedRoomId)) {
                          selectedRoomId = null;
                        }
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'ជ្រើសរើសអគារ',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: theme.colorScheme.onSurface.withOpacity(0.4),
                          width: 0.1,
                        ),
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surface,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                    dropdownColor: theme.colorScheme.surface,
                    icon: Icon(
                      Icons.filter_list,
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                    validator: (value) => null,
                  ),
                  fieldSpacing,
                  // Name Field
                  TextFormField(
                    initialValue: name,
                    decoration: InputDecoration(
                      labelText: 'ឈ្មោះអ្នកជួល',
                      labelStyle: theme.textTheme.bodyMedium,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'សូមបញ្ចូលឈ្មោះអ្នកជួល';
                      }
                      return null;
                    },
                    onSaved: (value) => name = value!,
                  ),
                  fieldSpacing,
                  // Phone Number Field
                  TextFormField(
                    initialValue: phoneNumber,
                    decoration: InputDecoration(
                      labelText: 'លេខទូរស័ព្ទ',
                      labelStyle: theme.textTheme.bodyMedium,
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'សូមបញ្ចូលលេខទូរស័ព្ទ';
                      }
                      return null;
                    },
                    onSaved: (value) => phoneNumber = value!,
                  ),
                  fieldSpacing,
                  // Room Dropdown - Fixed implementation
                  DropdownButtonFormField<String?>(
                    value: selectedRoomId,
                    items: availableRooms.map((room) {
                      return DropdownMenuItem<String?>(
                        value: room.id, // Use room ID as value
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('បន្ទប់: ${room.roomNumber}'),
                            Text('- ${room.building?.name ?? ''}'),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (String? value) {
                      setState(() {
                        selectedRoomId = value;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'បន្ទប់',
                      labelStyle: theme.textTheme.bodyMedium,
                    ),
                    validator: (value) =>
                        value == null ? 'សូមជ្រើសរើសបន្ទប់' : null,
                  ),
                  fieldSpacing,

                  // Gender Selection
                  DropdownButtonFormField<Gender>(
                    value: gender,
                    decoration: InputDecoration(
                      labelText: 'ភេទ',
                      labelStyle: theme.textTheme.bodyMedium,
                    ),
                    items: Gender.values
                        .map(
                          (g) => DropdownMenuItem(
                            value: g,
                            child: Text(
                              {
                                Gender.male: 'បុរស',
                                Gender.female: 'នារី',
                                Gender.other: 'ផ្សេងៗ',
                              }[g]!,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => gender = value!),
                    onSaved: (value) => gender = value!,
                  ),
                  const SizedBox(height: 24),
                  // Save Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        onPressed: _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                        ),
                        child: Text(
                          isEditing ? 'កែប្រអ្នកជួល' : 'បង្កើតអ្នកជួល',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error) => Center(
            child: Text(
              'មានបញ្ហាក្នុងការផ្ទុកអគារ: $error',
              style: theme.textTheme.titleMedium,
            ),
          ),
        ),
      ),
    );
  }
}
