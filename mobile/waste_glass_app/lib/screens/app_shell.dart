import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/trip_provider.dart';
import 'scan_collect_screen.dart';
import 'trip_report_screen.dart';
import 'trip_sequence_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  void _selectTab(int index) {
    final provider = context.read<TripProvider>();

    if (index == 2 && provider.trip?.isCompleted != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF005B49),
          content: Text(
            'Analytics unlocks after all stops are completed. ${provider.trip?.remainingStops ?? ''} stops remaining.',
          ),
        ),
      );
    }

    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/eco_pattern.png',
              fit: BoxFit.cover,
              opacity: const AlwaysStoppedAnimation(0.14),
            ),
          ),
          IndexedStack(
            index: _selectedIndex,
            children: [
              TripSequenceScreen(
                onScanPressed: () => _selectTab(1),
                onAnalyticsPressed: () => _selectTab(2),
              ),
              ScanCollectScreen(
                onCompleted: () => _selectTab(2),
                onGoHome: () => _selectTab(0),
              ),
              TripReportScreen(
                onGoHome: () => _selectTab(0),
                onStartScan: () => _selectTab(1),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: _EcoBottomNav(
        selectedIndex: _selectedIndex,
        onTap: _selectTab,
      ),
    );
  }
}

class _EcoBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _EcoBottomNav({
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      _NavItem(icon: Icons.home_rounded, label: 'Home'),
      _NavItem(icon: Icons.qr_code_scanner_rounded, label: 'Scan'),
      _NavItem(icon: Icons.insights_rounded, label: 'Analytics'),
    ];

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(22, 4, 22, 10),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: const Color(0xFFD8E8E1)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF003E34).withValues(alpha: 0.12),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: List.generate(items.length, (index) {
            final item = items[index];
            final selected = selectedIndex == index;

            return Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => onTap(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFF005B49)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.icon,
                        size: 22,
                        color: selected
                            ? Colors.white
                            : const Color(0xFF75868C),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.label,
                        style: TextStyle(
                          color: selected
                              ? Colors.white
                              : const Color(0xFF75868C),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;

  _NavItem({required this.icon, required this.label});
}
