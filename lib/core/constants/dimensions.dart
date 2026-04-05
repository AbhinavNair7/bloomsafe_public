// Base Spacing Unit
const double baseUnit = 8.0;

// Spacing Scale
const double spacingSmall = baseUnit; // 8px - tight elements
const double spacingMedium = baseUnit * 2; // 16px - within components
const double spacingLarge = baseUnit * 3; // 24px - between components
const double spacingSection = baseUnit * 4; // 32px - major sections

// Component Spacing
const double paddingStandard = spacingMedium; // 16px standard
const double paddingCompact = spacingSmall; // 8px for compact elements
const double marginBetweenRelated =
    spacingMedium; // 16px between related elements
const double marginBetweenSections =
    spacingLarge; // 24px between major sections

// Touch Target
const double minTouchTarget = 44.0; // Minimum size for interactive elements

// Responsive Breakpoints
const double breakpointMobile = 768.0;
const double breakpointTablet = 1024.0;
const double breakpointDesktop = 1025.0;
