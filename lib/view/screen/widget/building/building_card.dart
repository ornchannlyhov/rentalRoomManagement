import 'package:flutter/material.dart';
import 'package:receipts_v2/model/building.dart';
import 'package:receipts_v2/model/enum/room_status.dart';
import 'package:receipts_v2/model/room.dart';
import 'package:receipts_v2/repository/room_repository.dart';

class BuildingCard extends StatefulWidget {
  final Building? building;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const BuildingCard({
    super.key,
    this.building,
    this.onTap,
    this.onLongPress,
  });

  @override
  State<BuildingCard> createState() => _BuildingCardState();
}

class _BuildingCardState extends State<BuildingCard> {
  List<Room> rooms = [];
  final roomRepository = RoomRepository();
  @override
  void initState() {
    super.initState();
    _loadRoom();
  }

  Future<void> _loadRoom() async {
    await roomRepository.load();
    setState(() {
      rooms = roomRepository.getThisBuildingRooms(widget.building!.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final building = widget.building!;
    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
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
                  building.name,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "${building.rentPrice}\$",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 26,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Electric price: ${building.electricPrice}\$",
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
                Text(
                  "Water price: ${building.waterPrice}\$",
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            CircularIndicator(rooms: rooms),
          ],
        ),
      ),
    );
  }
}

class CircularIndicator extends StatefulWidget {
  final List<Room> rooms;
  const CircularIndicator({super.key, this.rooms = const []});
  @override
  State<CircularIndicator> createState() => _CircularIndicatorState();
}

class _CircularIndicatorState extends State<CircularIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;

  int get totalRooms => widget.rooms.length;
  int get occupiedRooms => widget.rooms
      .where((room) => room.roomStatus == RoomStatus.occupied)
      .length;

  @override
  void initState() {
    super.initState();

    final progress = _calculateProgress();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _progressAnimation = Tween<double>(begin: 0, end: progress).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  @override
  void didUpdateWidget(CircularIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);

    final newProgress = _calculateProgress();
    if (newProgress != _progressAnimation.value) {
      _progressAnimation =
          Tween<double>(begin: _progressAnimation.value, end: newProgress)
              .animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
      );

      _animationController
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  double _calculateProgress() {
    return totalRooms > 0 ? occupiedRooms / totalRooms : 0;
  }

  Color _getProgressColor(double progress) {
    if (progress < 0.2) {
      return Colors.red;
    } else if (progress < 0.4) {
      return Colors.yellow;
    } else {
      return Colors.greenAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _progressAnimation,
      builder: (context, child) {
        final progress = _progressAnimation.value;
        final progressColor = _getProgressColor(progress);

        return Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              height: 70,
              width: 70,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 6,
                color: progressColor,
                backgroundColor: Colors.grey.shade800,
              ),
            ),
            Column(
              children: [
                Text(
                  "$occupiedRooms/$totalRooms",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'occupied',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white38,
                  ),
                )
              ],
            )
          ],
        );
      },
    );
  }
}
