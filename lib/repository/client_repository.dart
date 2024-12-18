import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:receipts_v2/model/client.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ClientRepository {
  final String filePath = 'data/clients.jos';
  final String storageKey = 'clientData';

  List<Client> _clientCache = [];

  Future<void> _loadFromAsset() async {
    try {
      final String jsonString =
          await rootBundle.loadString('data/clients.json');
      final List<dynamic> jsonData = jsonDecode(jsonString);
      _clientCache =
          jsonData.map((clientJson) => Client.fromJson(clientJson)).toList();
    } catch (e) {
      throw Exception('Failed to laod client data from asset: $e');
    }
  }

  Future<void> _loadFromSharedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(storageKey);
      if (jsonString == null || jsonString.isEmpty) {
        _clientCache = [];
        return;
      }
      final List<dynamic> jsonData = jsonDecode(jsonString);
      _clientCache =
          jsonData.map((clientJson) => Client.fromJson(clientJson)).toList();
    } catch (e) {
      throw Exception('Failed to load client data from SharedPreferences: $e');
    }
  }

  Future<void> _loadFromFile() async {
    try {
      final file = File(filePath);
      if (file.existsSync()) {
        final jsonString = await file.readAsString();
        final List<dynamic> jsonData = jsonDecode(jsonString);
        _clientCache = jsonData
            .map((clientJson) => Client.fromJson(clientJson))
            .toList();
      } else {
        await _loadFromAsset();
        await save();
      }
    } catch (e) {
      throw Exception('Failed to load client data from file: $e');
    }
  }

  Future<void> _saveToFile() async {
    try {
      final file = File(filePath);
      final jsonString =
          jsonEncode(_clientCache.map((client) => client.toJson()).toList());
      await file.writeAsString(jsonString);
    } catch (e) {
      throw Exception('Failed to save client data to file: $e');
    }
  }

  Future<void> _saveToSharedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      prefs.setString(storageKey,
          jsonEncode(_clientCache.map((client) => client.toJson()).toList()));
    } catch (e) {
      throw Exception('Failed to save client data to SharedPreferences: $e');
    }
  }

  Future<void> save() async {
    if (kIsWeb) {
      await _saveToSharedPreferences();
    } else {
      await _saveToFile();
      await _saveToSharedPreferences();
    }
  }

  Future<void> load() async {
    if (kIsWeb) {
      await _loadFromSharedPreferences();
    } else {
      await _loadFromFile();
    }

    if (_clientCache.isEmpty) {
      await _loadFromAsset();
      await save();
    }
  }

  Future<void> createClient(Client newClient) async {
    _clientCache.add(newClient);
    await save();
  }

  Future<void> updateClient(Client updateClient) async {
    final index =
        _clientCache.indexWhere((client) => client.id == updateClient.id);
    if (index != -1) {
      _clientCache[index] = updateClient;
      await save();
    } else {
      throw Exception('client not found: ${updateClient.id}');
    }
  }

  Future<void> deleteClient(String clientId) async {
    _clientCache.removeWhere((client) => client.id == clientId);
    await save();
  }

  List<Client> getAllClient() {
    return List.from(_clientCache);
  }
}
