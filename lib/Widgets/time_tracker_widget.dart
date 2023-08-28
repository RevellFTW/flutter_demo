import 'package:flutter/material.dart';

class TimeTrackerWidget extends StatelessWidget {
  final Duration duration;

  const TimeTrackerWidget({super.key, required this.duration});

  String _formatDuration(Duration duration) {
    String formattedDuration = '';

    if (duration.inHours > 0) {
      formattedDuration += '${duration.inHours}ó ';
    }

    if (duration.inMinutes > 0) {
      formattedDuration += '${duration.inMinutes.remainder(60)}p ';
    }

    formattedDuration += '${duration.inSeconds.remainder(60)}mp';

    return formattedDuration.trim();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        color: Colors.grey[200],
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            _formatDuration(duration),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
