import 'package:flutter/material.dart';

// Brand Colors
const Color primaryColor = Color(
  0xFFB499AC,
); // Royal Purple - fertility, protection, wisdom
const Color secondaryColor = Color(
  0xFFA7BED3,
); // Columbia Blue - clean air, calm, clarity
const Color accentColor = Color(
  0xFFFFAFCC,
); // Pale Coral - alerts and important information
const Color neutralLight = Color(0xFFFFF1E6); // Vanilla - backgrounds
const Color neutralWhite = Color(0xFFFFFFFF); // White - backgrounds, cards

// PM2.5 Severity Level Colors (from screenshot)
const Color nurturingZoneColor = Color(0xFF4CAF50); // Green (0-50)
const Color mindfulZoneColor = Color(0xFFFFC107); // Yellow (51-100)
const Color cautiousZoneColor = Color(0xFFFF9800); // Orange (101-150)
const Color shieldZoneColor = Color(0xFFE53935); // Red (151-200)
const Color shelterZoneColor = Color(0xFF9C27B0); // Purple (201-300)
const Color protectionZoneColor = Color(0xFF673AB7); // Dark Purple (301+)

// Error State Colors
const Color errorColor = Color(0xFFE53935); // Red for errors
const Color warningColor = Color(0xFFFFC107); // Yellow for warnings
const Color successColor = Color(0xFF4CAF50); // Green for success
