// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl_phone_field/country_picker_dialog.dart';
import 'package:provider/provider.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:image_picker/image_picker.dart';
import 'package:joul_v2/data/models/enum/gender.dart';
import 'package:joul_v2/data/models/room.dart';
import 'package:joul_v2/data/models/tenant.dart';
import 'package:joul_v2/data/models/enum/mode.dart';
import 'package:joul_v2/l10n/app_localizations.dart';
import 'package:joul_v2/presentation/providers/building_provider.dart';
import 'package:joul_v2/presentation/providers/room_provider.dart';

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
  final ImagePicker _picker = ImagePicker();

  List<Room> availableRooms = [];
  List<Room> allRooms = [];

  late String id;
  late String name;
  late String phoneNumber;
  String? selectedRoomId;
  late Gender gender;
  String? selectedBuildingId;
  String? tenantProfile;
  XFile? _selectedImage;

  bool get isEditing => widget.mode == Mode.editing;

  @override
  void initState() {
    super.initState();
    selectedBuildingId = widget.selectedBuildingId;

    if (isEditing && widget.tenant != null) {
      final tenant = widget.tenant!;
      id = tenant.id;
      name = tenant.name;
      phoneNumber = tenant.phoneNumber;
      selectedRoomId = tenant.room?.id;
      gender = tenant.gender;
      tenantProfile = tenant.tenantProfile;
      if (tenant.room?.building != null) {
        selectedBuildingId = tenant.room!.building!.id;
      }
    } else {
      id = '';
      name = '';
      phoneNumber = '';
      selectedRoomId = null;
      gender = Gender.male;
      tenantProfile = null;
    }

    // Load rooms after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRooms();
    });
  }

  void _loadRooms() {
    final roomProvider = context.read<RoomProvider>();

    setState(() {
      allRooms = roomProvider.roomsState.when(
        success: (rooms) => rooms,
        loading: () => [],
        error: (_) => [],
      );

      availableRooms = roomProvider.getAvailableRooms();

      // Include the current room in availableRooms if editing
      if (isEditing && widget.tenant?.room != null) {
        final currentRoom = allRooms.firstWhere(
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
  }

  void _filterRoomsByBuilding() {
    final roomProvider = context.read<RoomProvider>();

    if (selectedBuildingId != null) {
      availableRooms = roomProvider
          .getAvailableRooms()
          .where((room) => room.building?.id == selectedBuildingId)
          .toList();
    } else {
      availableRooms = roomProvider.getAvailableRooms();
    }

    // Include current room if editing
    if (isEditing && widget.tenant?.room != null) {
      final currentRoom = allRooms.firstWhere(
        (room) => room.id == widget.tenant!.room!.id,
        orElse: () => widget.tenant!.room!,
      );
      if (!availableRooms.any((room) => room.id == currentRoom.id)) {
        availableRooms.add(currentRoom);
      }
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
          _selectedImage = image;
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

  void _save() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // Find the selected room object from the ID
      Room? selectedRoom;
      if (selectedRoomId != null) {
        selectedRoom = allRooms.firstWhere(
          (room) => room.id == selectedRoomId,
          orElse: () => availableRooms.firstWhere(
            (room) => room.id == selectedRoomId,
          ),
        );
      }

      // Use selected image path if new image was picked, otherwise keep existing
      String? profilePath = tenantProfile;
      if (_selectedImage != null) {
        profilePath = _selectedImage!.path;
      }

      final newTenant = Tenant(
        id: isEditing
            ? widget.tenant!.id
            : 'temp_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        phoneNumber: phoneNumber,
        gender: gender,
        room: selectedRoom,
        chatId: widget.tenant?.chatId,
        language: widget.tenant?.language ?? 'english',
        lastInteractionDate:
            widget.tenant?.lastInteractionDate ?? DateTime.now(),
        nextReminderDate: widget.tenant?.nextReminderDate,
        isActive: widget.tenant?.isActive ?? true,
        deposit: widget.tenant?.deposit ?? 0.0,
        tenantProfile: profilePath,
        createdAt: widget.tenant?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      Navigator.pop(context, newTenant);
    }
  }

  String _getGenderText(BuildContext context, Gender g) {
    final localizations = AppLocalizations.of(context)!;
    switch (g) {
      case Gender.male:
        return localizations.male;
      case Gender.female:
        return localizations.female;
      case Gender.other:
        return localizations.other;
    }
  }

  Widget _buildProfileImagePicker(ThemeData theme) {
    return Column(
      children: [
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: _selectedImage != null
                ? ClipOval(
                    child: Image.file(
                      File(_selectedImage!.path),
                      fit: BoxFit.cover,
                    ),
                  )
                : tenantProfile != null && tenantProfile!.isNotEmpty
                    ? ClipOval(
                        child: tenantProfile!.startsWith('http')
                            ? Image.network(
                                tenantProfile!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.person,
                                    size: 60,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  );
                                },
                              )
                            : Image.file(
                                File(tenantProfile!),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.person,
                                    size: 60,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  );
                                },
                              ),
                      )
                    : Icon(
                        Icons.add_a_photo,
                        size: 40,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
          ),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: _pickImage,
          icon: const Icon(Icons.photo_library, size: 18),
          label: Text(
            _selectedImage != null || tenantProfile != null
                ? 'Change Photo'
                : 'Add Photo',
            style: theme.textTheme.bodySmall,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;
    const fieldSpacing = SizedBox(height: 12);
    final buildingProvider = context.watch<BuildingProvider>();
    final roomProvider = context.watch<RoomProvider>();

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        title: Text(
            isEditing ? localizations.editTenant : localizations.createNewTenant),
        actions: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.cancel),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: buildingProvider.buildingsState.when(
          success: (buildings) {
            return roomProvider.roomsState.when(
              success: (rooms) {
                // Update rooms when provider data changes
                if (allRooms.isEmpty || allRooms.length != rooms.length) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _loadRooms();
                  });
                }

                return Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      // Profile Image Picker
                      Center(child: _buildProfileImagePicker(theme)),
                      const SizedBox(height: 24),

                      // Building Filter
                      DropdownButtonFormField<String?>(
                        value: selectedBuildingId,
                        items: [
                          DropdownMenuItem(
                            value: null,
                            child: Text(
                              localizations.all,
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
                          labelText: localizations.selectBuilding,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.4),
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
                          labelText: localizations.tenantNameLabel,
                          labelStyle: theme.textTheme.bodyMedium,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return localizations.pleaseEnterTenantName;
                          }
                          return null;
                        },
                        onSaved: (value) => name = value!,
                      ),
                      fieldSpacing,
                      // Phone Number Field with Country Picker
                      IntlPhoneField(
                        decoration: InputDecoration(
                          labelText: localizations.phoneNumber,
                          labelStyle: theme.textTheme.bodyMedium,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                        initialCountryCode: 'KH',
                        initialValue: phoneNumber.startsWith('+')
                            ? phoneNumber
                                .substring(phoneNumber.indexOf(' ') + 1)
                                .replaceAll(' ', '')
                            : phoneNumber,
                        onChanged: (phone) {
                          phoneNumber = phone.completeNumber;
                        },
                        onSaved: (phone) {
                          if (phone != null) {
                            phoneNumber = phone.completeNumber;
                          }
                        },
                        validator: (phone) {
                          if (phone == null || phone.number.isEmpty) {
                            return localizations.pleaseEnterPhoneNumber;
                          }
                          return null;
                        },
                        invalidNumberMessage: localizations.invalidPhoneNumber,
                        searchText: localizations.searchCountry,
                        disableLengthCheck: true,
                        pickerDialogStyle: PickerDialogStyle(
                          backgroundColor: theme.colorScheme.surface,
                          searchFieldInputDecoration: InputDecoration(
                            labelText: localizations.searchCountry,
                            labelStyle: theme.textTheme.bodyMedium,
                          ),
                          countryCodeStyle: theme.textTheme.bodyMedium,
                          countryNameStyle: theme.textTheme.bodyMedium,
                          listTileDivider: Divider(
                            color: theme.colorScheme.onSurface.withOpacity(0.1),
                            height: 1,
                            thickness: 0.5,
                          ),
                          listTilePadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                      fieldSpacing,
                      // Gender Selection
                      DropdownButtonFormField<Gender>(
                        value: gender,
                        decoration: InputDecoration(
                          labelText: localizations.gender,
                          labelStyle: theme.textTheme.bodyMedium,
                        ),
                        items: Gender.values
                            .map(
                              (g) => DropdownMenuItem(
                                value: g,
                                child: Text(_getGenderText(context, g)),
                              ),
                            )
                            .toList(),
                        onChanged: (value) => setState(() => gender = value!),
                        onSaved: (value) => gender = value!,
                      ),
                      fieldSpacing,
                      // Room Dropdown
                      DropdownButtonFormField<String?>(
                        value: selectedRoomId,
                        items: availableRooms.map((room) {
                          return DropdownMenuItem<String?>(
                            value: room.id,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                    '${localizations.room}: ${room.roomNumber}'),
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
                          labelText: localizations.room,
                          labelStyle: theme.textTheme.bodyMedium,
                        ),
                        validator: (value) => value == null
                            ? localizations.pleaseSelectRoom
                            : null,
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
                              isEditing
                                  ? localizations.updateTenant
                                  : localizations.createTenant,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
              loading: () => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      localizations.loading,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              error: (error) => Center(
                child: Text(
                  '${localizations.errorLoadingRooms}: $error',
                  style: theme.textTheme.titleMedium,
                ),
              ),
            );
          },
          loading: () => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  localizations.loading,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          error: (error) => Center(
            child: Text(
              '${localizations.errorLoadingBuildings}: $error',
              style: theme.textTheme.titleMedium,
            ),
          ),
        ),
      ),
    );
  }
}