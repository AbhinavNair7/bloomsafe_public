import 'package:flutter/material.dart';
import 'package:bloomsafe/core/utils/app_initializer.dart';
import 'package:bloomsafe/flavors.dart';
import 'app.dart';

/// Development flavor entry point
/// 
/// This initializes the app with development environment configuration,
/// loading .env.dev and setting up development-specific services.
void main() async {
  try {
    // Initialize app with development flavor
    await AppInitializer.initialize(flavor: Flavor.dev);
    
    // Run the app
    runApp(const App());
  } catch (e) {
    // Run fallback error app if initialization fails
    runApp(_ErrorApp(error: e.toString()));
  }
}

/// Simple error UI for initialization failures
class _ErrorApp extends StatelessWidget {
  const _ErrorApp({required this.error});
  
  final String error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 60),
                const SizedBox(height: 20),
                const Text('Initialization Error', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Text(error, style: const TextStyle(fontSize: 14), textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
