import 'package:flutter/material.dart';
import 'package:receipts_v2/model/client.dart';
import 'package:receipts_v2/model/enum/gender.dart';

class ClientCard extends StatelessWidget {
  final Client client;
  final VoidCallback onTap;

  const ClientCard({super.key, required this.client, required this.onTap});

  String getAvatar() {
    switch (client.gender) {
      case Gender.female:
        return 'assets/avatar/female_avatar.png';
      case Gender.male:
        return 'assets/avatar/male_avatar.png';
      case Gender.other:
        return 'assets/avatar/lgbtq+_avatar.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: onTap,
        child: Card(
          color: const Color.fromARGB(255, 18, 13, 29),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          margin: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 8.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    getAvatar(),
                    height: 70,
                    width: 70,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        client.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Building: ${client.room!.building!.name}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Room number: ${client.room!.roomNumber}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Phone number: ${client.phoneNumber}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ));
  }
}
