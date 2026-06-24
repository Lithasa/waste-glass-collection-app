import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/trip_model.dart';
import '../providers/trip_provider.dart';

class TripSequenceScreen extends StatefulWidget {
  final VoidCallback? onScanPressed;
  final VoidCallback? onAnalyticsPressed;

  const TripSequenceScreen({
    super.key,
    this.onScanPressed,
    this.onAnalyticsPressed,
  });

  @override
  State<TripSequenceScreen> createState() => _TripSequenceScreenState();
}

class _TripSequenceScreenState extends State<TripSequenceScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TripProvider>().loadTodayTrip();
    });
  }

  Future<void> _handleDebugReset() async {
    await context.read<TripProvider>().resetDemoTrip();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TripProvider>();
    final trip = provider.trip;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () => context.read<TripProvider>().loadTodayTrip(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 92),
          children: [
            _TopBar(
              onRefresh: provider.isLoading
                  ? null
                  : () => context.read<TripProvider>().loadTodayTrip(),
              onDebugReset: _handleDebugReset,
            ),
            const SizedBox(height: 14),
            if (provider.errorMessage != null)
              _MessageCard(message: provider.errorMessage!, isError: true),
            if (provider.successMessage != null)
              _MessageCard(message: provider.successMessage!, isError: false),
            _HeroSummaryCard(trip: trip),
            const SizedBox(height: 14),
            _ActionPanel(
              trip: trip,
              onScanPressed: widget.onScanPressed,
              onAnalyticsPressed: widget.onAnalyticsPressed,
            ),
            const SizedBox(height: 22),
            const Center(
              child: Text(
                'Today’s optimized stop sequence',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF071426),
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                  height: 1.15,
                ),
              ),
            ),
            const SizedBox(height: 14),
            if (provider.isLoading && trip == null)
              const _LoadingCard()
            else if (trip == null)
              const _EmptyState()
            else
              ...trip.stops.map((stop) => _StopCard(stop: stop)),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final VoidCallback? onRefresh;
  final VoidCallback? onDebugReset;

  const _TopBar({required this.onRefresh, required this.onDebugReset});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Waste Glass',
                style: TextStyle(
                  color: Color(0xFF071426),
                  fontSize: 29,
                  fontWeight: FontWeight.w900,
                  height: 1.0,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Collection Route',
                style: TextStyle(
                  color: Color(0xFF73838B),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onLongPress: onDebugReset,
          child: IconButton.filledTonal(
            onPressed: onRefresh,
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFD6EFE3),
              foregroundColor: const Color(0xFF005B49),
              fixedSize: const Size(46, 46),
            ),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ),
      ],
    );
  }
}

class _HeroSummaryCard extends StatelessWidget {
  final TripModel? trip;

  const _HeroSummaryCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    final completed = trip?.isCompleted ?? false;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFF005B49),
        borderRadius: BorderRadius.circular(31),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF003E34).withValues(alpha: 0.20),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF003E34), Color(0xFF005B49)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: 10,
                  top: 12,
                  child: Icon(
                    Icons.recycling_rounded,
                    size: 130,
                    color: Colors.white.withValues(alpha: 0.065),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCFEBDD).withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.recycling_rounded,
                        color: Colors.white,
                        size: 31,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      completed ? 'Trip completed' : 'Collection trip',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      trip == null
                          ? 'Route will load from your .NET backend.'
                          : '${trip!.remainingStops} stops remaining • ${trip!.totalRouteDistanceKm.toStringAsFixed(2)} km route',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.84),
                        fontSize: 14,
                        height: 1.35,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          ClipPath(
            clipper: _WaveClipper(),
            child: Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 30, 20, 18),
              child: Row(
                children: [
                  _MiniMetric(
                    label: 'Distance',
                    value: trip == null
                        ? '--'
                        : '${trip!.totalRouteDistanceKm.toStringAsFixed(2)} km',
                  ),
                  const SizedBox(width: 10),
                  _MiniMetric(
                    label: 'Remaining',
                    value: trip == null ? '--' : '${trip!.remainingStops}',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 18);
    path.quadraticBezierTo(size.width * 0.25, 0, size.width * 0.50, 18);
    path.quadraticBezierTo(size.width * 0.75, 36, size.width, 18);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _MiniMetric extends StatelessWidget {
  final String label;
  final String value;

  const _MiniMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF7F2),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF73838B),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Color(0xFF071426),
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionPanel extends StatelessWidget {
  final TripModel? trip;
  final VoidCallback? onScanPressed;
  final VoidCallback? onAnalyticsPressed;

  const _ActionPanel({
    required this.trip,
    required this.onScanPressed,
    required this.onAnalyticsPressed,
  });

  @override
  Widget build(BuildContext context) {
    final nextStop = trip?.nextStop;
    final completed = trip?.isCompleted == true;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: nextStop == null ? null : onScanPressed,
                icon: const Icon(Icons.qr_code_scanner_rounded, size: 19),
                label: Text(completed ? 'All collected' : 'Scan next supplier'),
              ),
            ),
            const SizedBox(height: 9),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onAnalyticsPressed,
                icon: const Icon(Icons.insights_rounded, size: 19),
                label: Text(
                  completed
                      ? 'Open completed analytics'
                      : 'Analytics unlocks after all stops',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StopCard extends StatelessWidget {
  final TripStopModel stop;

  const _StopCard({required this.stop});

  @override
  Widget build(BuildContext context) {
    final isNext = stop.status.toLowerCase() == 'next';
    final isCollected = stop.status.toLowerCase() == 'collected';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: isCollected ? const Color(0xFF005B49) : const Color(0xFF003E34),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF003E34).withValues(alpha: 0.10),
            blurRadius: 12,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isNext
                  ? const Color(0xFFFFD166)
                  : Colors.white.withValues(alpha: 0.13),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '${stop.sequenceNo}',
              style: TextStyle(
                color: isNext ? const Color(0xFF003E34) : Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stop.supplier.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  stop.supplier.address,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.70),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 9),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    _StatusChip(status: stop.status),
                    _MiniInfo(
                      icon: Icons.route_rounded,
                      text:
                          '${stop.distanceFromPreviousKm.toStringAsFixed(2)} km',
                    ),
                    _MiniInfo(
                      icon: Icons.scale_rounded,
                      text:
                          '${stop.supplier.expectedTotalKg.toStringAsFixed(0)} kg',
                    ),
                    _MiniInfo(
                      icon: Icons.qr_code_rounded,
                      text: stop.supplier.barcodeValue,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'collected':
        bg = const Color(0xFFE8FFF3);
        fg = const Color(0xFF005B49);
        icon = Icons.check_circle_rounded;
        break;
      case 'next':
        bg = const Color(0xFFFFD166);
        fg = const Color(0xFF003E34);
        icon = Icons.navigation_rounded;
        break;
      default:
        bg = Colors.white.withValues(alpha: 0.13);
        fg = Colors.white;
        icon = Icons.schedule_rounded;
    }

    return _Pill(bg: bg, fg: fg, icon: icon, text: status);
  }
}

class _MiniInfo extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MiniInfo({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return _Pill(
      bg: Colors.white.withValues(alpha: 0.13),
      fg: Colors.white,
      icon: icon,
      text: text,
    );
  }
}

class _Pill extends StatelessWidget {
  final Color bg;
  final Color fg;
  final IconData icon;
  final String text;

  const _Pill({
    required this.bg,
    required this.fg,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w900,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  final String message;
  final bool isError;

  const _MessageCard({required this.message, required this.isError});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        color: isError ? const Color(0xFFFFF1F2) : const Color(0xFFE8FFF3),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(
                isError ? Icons.error_rounded : Icons.check_circle_rounded,
                color: isError
                    ? const Color(0xFFE11D48)
                    : const Color(0xFF005B49),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: isError
                        ? const Color(0xFF9F1239)
                        : const Color(0xFF005B49),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(22),
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(22),
        child: Center(
          child: Text(
            'No trip loaded. Pull to refresh.',
            style: TextStyle(color: Color(0xFF73838B)),
          ),
        ),
      ),
    );
  }
}
