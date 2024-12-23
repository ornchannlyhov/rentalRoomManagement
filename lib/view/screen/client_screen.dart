import 'package:flutter/material.dart';
import 'package:receipts_v2/model/client.dart';
import 'package:receipts_v2/model/enum/mode.dart';
import 'package:receipts_v2/model/room.dart';
import 'package:receipts_v2/repository/client_repository.dart';
import 'package:receipts_v2/repository/room_repository.dart';
import 'package:receipts_v2/view/appComponent/app_bar.dart';
import 'package:receipts_v2/view/widget/clientWidgets/client_card.dart';
import 'package:receipts_v2/view/widget/clientWidgets/client_form.dart';

class ClientScreen extends StatefulWidget {
  const ClientScreen({super.key});

  @override
  State<ClientScreen> createState() => _ClientScreenState();
}

class _ClientScreenState extends State<ClientScreen> {
  List<Client> clients = [];
  List<Room> rooms = [];

  final clientRepository = ClientRepository();
  final roomRepository = RoomRepository();

  @override
  void initState() {
    super.initState();
    _loadClients();
  }

  Future<void> _loadClients() async {
    await clientRepository.load();
    await roomRepository.load();
    setState(() {
      clients = clientRepository.getAllClient();
      rooms = roomRepository.getAllRooms();
    });
  }

  Future<void> _addClient(BuildContext context, List<Client> clients) async {
    final newClient = await Navigator.of(context).push<Client>(
      MaterialPageRoute(
        builder: (ctx) => const ClientForm(
          mode: Mode.creating,
        ),
      ),
    );

    if (newClient != null) {
      await clientRepository.createClient(newClient);
      await roomRepository.addClient(newClient.room!.id, newClient);
      await roomRepository.updateToOccupied(newClient.room!.id);
      _loadClients();
    }
  }

  Future<void> _editClient(BuildContext context, Client client) async {
    final updateClient = await Navigator.of(context).push<Client>(
      MaterialPageRoute(
        builder: (ctx) => ClientForm(
          mode: Mode.editing,
          client: client,
        ),
      ),
    );
    if (updateClient != null) {
      await clientRepository.updateClient(updateClient);
      await roomRepository.addClient(updateClient.room!.id, updateClient);
      _loadClients();
    }
  }

  void _deleteClient(BuildContext context, int index, Client client) {
    clientRepository.deleteClient(client.id);
    roomRepository.updateToAvailable(client.room!.id);
    roomRepository.removeClient(client.room!.id);
    setState(() {
      clients.removeAt(index);
    });
    final removedClient = client;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 3),
        content: Text(' "${client.name}" deleted'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            roomRepository.updateToOccupied(removedClient.room!.id);
            clientRepository.restoreClient(index, removedClient);
            setState(() {
              clients.insert(index, removedClient);
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppbarCustom(
        header: 'clients',
        onAddPressed: () => _addClient(context, clients),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
        child: clients.isEmpty
            ? const Center(
                child: Text(
                  'No clients available',
                  style: TextStyle(fontSize: 14, color: Colors.white),
                ),
              )
            : ListView.builder(
                itemCount: clients.length,
                itemBuilder: (ctx, index) {
                  final building = clients[index];
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
                          _deleteClient(context, index, building),
                      child: ClientCard(
                          client: clients[index],
                          onTap: () => _editClient(context, clients[index])));
                },
              ),
      ),
    );
  }
}
