import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bloomsafe/core/di/service_locator.dart' as di;
import 'package:bloomsafe/core/theme/app_theme.dart';
import 'package:bloomsafe/features/aqi_monitoring/presentation/state/aqi_provider.dart';
import 'package:bloomsafe/features/guide/presentation/state/guide_provider.dart';
import 'package:bloomsafe/features/learn/presentation/state/learn_provider.dart';
import 'package:bloomsafe/core/presentation/widgets/main_scaffold.dart';

import 'flavors.dart';

/// Main BloomSafe application widget
class BloomSafeApp extends StatelessWidget {
  /// Creates a new BloomSafeApp
  const BloomSafeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => di.sl<AQIProvider>()),
        ChangeNotifierProvider(create: (_) => di.sl<GuideProvider>()),
        ChangeNotifierProvider(create: (_) => di.sl<LearnProvider>()),
      ],
      child: MaterialApp(
        title: F.title,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.getLightTheme(),
        home: _flavorBanner(child: const MainScaffold()),
      ),
    );
  }

  Widget _flavorBanner({required Widget child}) {
    // Only show banner in dev mode, not in prod
    if (F.appFlavor == Flavor.dev) {
      return Banner(
        location: BannerLocation.topStart,
        message: F.name,
        color: Colors.orange.withAlpha(200),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 12.0,
          letterSpacing: 1.0,
        ),
        textDirection: TextDirection.ltr,
        child: child,
      );
    } else {
      // In prod mode, return the child without a banner
      return child;
    }
  }
}

// Export App for backward compatibility
typedef App = BloomSafeApp;