import 'dart:math' as math;

import 'package:bootstrap_icons/bootstrap_icons.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:iot_water_level_track/screen/alarm_notification_screen.dart';
import 'package:iot_water_level_track/screen/analysis_screen.dart';
import 'package:iot_water_level_track/screen/home_screen.dart';
import 'package:iot_water_level_track/screen/settings_screen.dart';

import 'dart:math';

import 'package:iot_water_level_track/screen/splash_screen.dart';
import 'package:flutter/animation.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const WaterPumpTrackerApp());
}


class WaterPumpTrackerApp extends StatelessWidget {
  const WaterPumpTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AquaTrack',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Inter',
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Colors.white,
          iconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _waveController;
  late AnimationController _fillController;

  final List<Widget> _screens = [
    const HomeScreen(),
    const AnalysisScreen(),
    const AlarmScreen(),

  ];

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _fillController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();
  }

  @override
  void dispose() {
    _waveController.dispose();
    _fillController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _screens[_currentIndex],
      ),
      bottomNavigationBar: _buildAnimatedBottomBar(),
    );
  }

  Widget _buildAnimatedBottomBar() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF00A8E8),
          unselectedItemColor: Colors.grey,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          items: [
            BottomNavigationBarItem(
              icon: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: _currentIndex == 0
                      ? const Color(0xFF00A8E8).withOpacity(0.1)
                      : Colors.transparent,
                ),
                child: Icon(
                 BootstrapIcons.house,
                  color: _currentIndex == 0
                      ? const Color(0xFF00A8E8)
                      : Colors.grey,
                 // height: 24,
                ),
              ),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: _currentIndex == 1
                      ? const Color(0xFF00A8E8).withOpacity(0.1)
                      : Colors.transparent,
                ),
                child: Icon(
                 BootstrapIcons.clipboard_data,
                  color: _currentIndex == 1
                      ? const Color(0xFF00A8E8)
                      : Colors.grey,
                 // height: 24,
                ),
              ),
              label: 'Analysis',
            ),
            BottomNavigationBarItem(
              icon: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: _currentIndex == 2
                      ? const Color(0xFF00A8E8).withOpacity(0.1)
                      : Colors.transparent,
                ),
                child: Badge(
                  isLabelVisible: _currentIndex != 2,
                  child: Icon(
                   BootstrapIcons.bell,
                    color: _currentIndex == 2
                        ? const Color(0xFF00A8E8)
                        : Colors.grey,
                  //  height: 24,
                  ),
                ),
              ),
              label: 'Alarms',
            ),

          ],
        ),
      ),
    );
  }
}
































