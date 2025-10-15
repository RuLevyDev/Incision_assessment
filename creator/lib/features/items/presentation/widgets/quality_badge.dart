import 'package:flutter/material.dart';

import '../../domain/value_objects/quality_score.dart';

class QualityBadge extends StatelessWidget {
  const QualityBadge({required this.score, required this.band, super.key});

  final int score;
  final QualityBand band;

  static const Map<QualityBand, Color> _bandColors = {
    QualityBand.poor: Colors.redAccent,
    QualityBand.fair: Colors.orangeAccent,
    QualityBand.good: Colors.blueAccent,
    QualityBand.excellent: Colors.green,
  };

  static const Map<QualityBand, String> _bandLabels = {
    QualityBand.poor: 'Poor',
    QualityBand.fair: 'Fair',
    QualityBand.good: 'Good',
    QualityBand.excellent: 'Excellent',
  };

  @override
  Widget build(BuildContext context) {
    final color = _bandColors[band] ?? Theme.of(context).colorScheme.primary;
    final label = _bandLabels[band] ?? band.name;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$score • $label',
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}
