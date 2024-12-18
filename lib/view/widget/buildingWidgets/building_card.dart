import 'package:flutter/material.dart';
import 'package:receipts_v2/model/enum/room_status.dart';
import 'package:receipts_v2/view/widget/buildingWidgets/circle_progress.dart';
import 'package:receipts_v2/model/building.dart';

class BuildingCard extends StatelessWidget {
  final Building? building;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const BuildingCard({
    super.key,
    this.building,
    this.onTap,
    this.onLongPress
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 18, 13, 29),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.deepPurple.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  building!.name,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "${building!.rentPrice}\$",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 26,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Electric price: ${building!.electricPrice}\$",
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
                Text(
                  "Water price: ${building!.waterPrice}\$",
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            CircularIndicator(
              totalRooms: building!.rooms.length,
              occupiedRooms: building!.rooms
                  .where((room) => room.roomStatus == RoomStatus.occupied)
                  .length,
            ),
          ],
        ),
      ),
    );
  }
}
