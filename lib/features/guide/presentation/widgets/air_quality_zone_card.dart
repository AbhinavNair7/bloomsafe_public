import 'package:flutter/material.dart';
import 'package:bloomsafe/core/constants/dimensions.dart';
import 'package:bloomsafe/features/guide/data/models/guide_item.dart';

/// A card that displays air quality zone information
class AirQualityZoneCard extends StatelessWidget {

  /// Creates an air quality zone card
  const AirQualityZoneCard({super.key, required this.zone});
  /// The air quality zone to display
  final AirQualityZone zone;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: spacingMedium),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(spacingMedium),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Zone color indicator
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: zone.color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
            const SizedBox(width: spacingMedium),

            // Zone content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and index range
                  Row(
                    children: [
                      Text(
                        zone.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: spacingSmall),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: zone.color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'AQI ${zone.indexRange}',
                          style: TextStyle(
                            fontSize: 12,
                            color: zone.color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: spacingSmall),

                  // Description
                  Text(zone.description, style: const TextStyle(fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
