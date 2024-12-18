import 'package:flutter/material.dart';

class CircularIndicator extends StatefulWidget {
  final int totalRooms;
  final int occupiedRooms;

  const CircularIndicator({
    super.key,
    required this.totalRooms,
    required this.occupiedRooms,
  });

  @override
  State<CircularIndicator> createState() => _CircularIndicatorState();
}

class _CircularIndicatorState extends State<CircularIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;

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
      _progressAnimation = Tween<double>(begin: _progressAnimation.value, end: newProgress).animate(
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
    return widget.totalRooms > 0 ? widget.occupiedRooms / widget.totalRooms : 0;
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
                  "${widget.occupiedRooms}/${widget.totalRooms}",
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
