import 'package:flutter/material.dart';
import 'package:bloomsafe/core/constants/colors.dart';
import 'package:bloomsafe/features/aqi_monitoring/presentation/screens/track_home_page.dart';
import 'package:bloomsafe/features/guide/presentation/screens/guide_screen.dart';
import 'package:bloomsafe/features/learn/presentation/screens/learn_screen.dart';

/// Main scaffold with bottom navigation bar and main screens
class MainScaffold extends StatefulWidget {
  /// Creates a main scaffold with navigation
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  // Current tab index
  int _currentIndex = 1; // Start with Track (middle) selected

  // Track tab overlay (for AQI results)
  Widget? _aqiResultsScreen;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // Guide tab (left)
          const GuideScreen(),

          // Track tab (middle)
          _aqiResultsScreen ??
              TrackHomePage(
                setAQIResultScreen: (screen) {
                  setState(() {
                    _aqiResultsScreen = screen;
                  });
                },
                clearAQIResultScreen: () {
                  setState(() {
                    _aqiResultsScreen = null;
                  });
                },
              ),

          // Learn tab (right)
          const LearnScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'Guide'),
          BottomNavigationBarItem(icon: Icon(Icons.air), label: 'Track'),
          BottomNavigationBarItem(
            icon: Icon(Icons.lightbulb_outline),
            label: 'Learn',
          ),
        ],
      ),
    );
  }

  void _onTabTapped(int index) {
    // If showing AQI results and user taps Track tab again, clear the results
    if (index == 1 && _currentIndex == 1 && _aqiResultsScreen != null) {
      setState(() {
        _aqiResultsScreen = null;
      });
      return;
    }

    setState(() {
      _currentIndex = index;
    });
  }
}
