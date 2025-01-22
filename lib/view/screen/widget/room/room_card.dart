import 'package:flutter/material.dart';
import 'package:receipts_v2/model/room.dart';

class RoomCard extends StatelessWidget {
  final Room room;
  final bool status;
  final VoidCallback onTap;

  const RoomCard({
    super.key,
    required this.room,
    required this.status,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 8.0),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 18, 13, 29),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Room ${room.roomNumber}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                    Icon(
                      Icons.circle,
                      color: status ? Colors.greenAccent : Colors.redAccent,
                      size: 18,
                    ),
                  ],
                ),
                const SizedBox(
                  height: 4,
                ),
                Text(
                  'Room Owner: ${room.client?.name ?? 'Unknown'}',
                  style: const TextStyle(fontSize: 10, color: Colors.white38),
                ),
                Text(
                  'Rent Price: ${room.price}\$',
                  style: const TextStyle(fontSize: 10, color: Colors.white38),
                )
              ])),
    );
  }
}
