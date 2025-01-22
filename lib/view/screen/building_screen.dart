import 'package:flutter/material.dart';
import 'package:receipts_v2/model/building.dart';
import 'package:receipts_v2/model/enum/mode.dart';
import 'package:receipts_v2/model/service.dart';
import 'package:receipts_v2/repository/buidling_repository.dart';
import 'package:receipts_v2/repository/service_repository.dart';
import 'package:receipts_v2/view/appComponent/app_bar.dart';
import 'package:receipts_v2/view/screen/widget/building/building_card.dart';
import 'package:receipts_v2/view/screen/widget/building/building_detail.dart';
import 'package:receipts_v2/view/screen/widget/building/building_form.dart';

class BuildingScreen extends StatefulWidget {
  const BuildingScreen({super.key});

  @override
  State<BuildingScreen> createState() => _BuildingScreenState();
}

class _BuildingScreenState extends State<BuildingScreen> {
  final BuildingRepository buildingRepository = BuildingRepository();
  final ServiceRepository serviceRepository = ServiceRepository();
  List<Building> buildings = [];
  List<Service> services = [];

  @override
  void initState() {
    super.initState();
    _loadBuildings();
  }

  Future<void> _loadBuildings() async {
    await buildingRepository.load();
    await serviceRepository.load();
    setState(() {
      buildings = buildingRepository.getAllBuildings();
      services = serviceRepository.getAllServices();
    });
  }

  Future<void> _addReceipt(
      BuildContext context, List<Building> buildings) async {
    final newReceipt = await Navigator.of(context).push<Building>(
      MaterialPageRoute(
        builder: (ctx) => BuildingForm(
          buildings: buildings,
        ),
      ),
    );

    if (newReceipt != null) {
      await buildingRepository.createBuilding(newReceipt);
      _loadBuildings();
    }
  }

  Future<void> _editReceipt(BuildContext context, Building buidling) async {
    final updatedReceipt = await Navigator.of(context).push<Building>(
      MaterialPageRoute(
        builder: (ctx) => BuildingForm(
          mode: Mode.editing,
          building: buidling,
          buildings: buildings,
        ),
      ),
    );
    if (updatedReceipt != null) {
      await buildingRepository.updateBuilding(updatedReceipt);
      _loadBuildings();
    }
  }

  Future<void> _viewBuilding(BuildContext context, Building building) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) =>
            BuildingDetail(building: building, services: services),
      ),
    );
    _loadBuildings();
  }

  void _deleteBuilding(BuildContext context, int index, Building building) {
    buildingRepository.deleteBuilding(building.id);
    setState(() {
      buildings.removeAt(index);
      building.rooms.clear();
    });
    final removedBuilding = building;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 3),
        content: Text('Building "${building.name}" deleted'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            buildingRepository.restoreBuilding(index, removedBuilding);
            setState(() {
              buildings.insert(index, removedBuilding);
            });
          },
        ),
      ),
    );
    _loadBuildings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppbarCustom(
        header: 'Buildings',
        onAddPressed: () => _addReceipt(context, buildings),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
        child: buildings.isEmpty
            ? const Center(
                child: Text(
                  'No buildings available',
                  style: TextStyle(fontSize: 14, color: Colors.white),
                ),
              )
            : ListView.builder(
                itemCount: buildings.length,
                itemBuilder: (ctx, index) {
                  final building = buildings[index];
                  return Dismissible(
                    key: Key(building.id),
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    direction: DismissDirection.endToStart,
                    onDismissed: (_) =>
                        _deleteBuilding(context, index, building),
                    child: BuildingCard(
                      building: building,
                      onTap: () => _viewBuilding(context, building),
                      onLongPress: () => _editReceipt(context, building),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
