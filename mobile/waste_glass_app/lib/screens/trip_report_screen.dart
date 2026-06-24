import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/trip_provider.dart';

class TripReportScreen extends StatefulWidget {
  final VoidCallback? onGoHome;
  final VoidCallback? onStartScan;

  const TripReportScreen({
    super.key,
    this.onGoHome,
    this.onStartScan,
  });

  @override
  State<TripReportScreen> createState() => _TripReportScreenState();
}

class _TripReportScreenState extends State<TripReportScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<TripProvider>();
      if (provider.trip?.isCompleted == true) {
        provider.loadReport();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TripProvider>();
    final trip = provider.trip;
    final report = provider.report;
    final suppliers = (report?['suppliers'] as List<dynamic>? ?? []);
    final completed = trip?.isCompleted == true ||
        report?['status']?.toString().toLowerCase() == 'completed';

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          final provider = context.read<TripProvider>();
          if (provider.trip?.isCompleted == true) {
            await provider.loadReport();
          } else {
            await provider.loadTodayTrip();
          }
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 92),
          children: [
            const _AnalyticsTitle(),
            const SizedBox(height: 14),
            if (provider.errorMessage != null)
              _MessageCard(message: provider.errorMessage!, isError: true),
            if (provider.successMessage != null)
              _MessageCard(message: provider.successMessage!, isError: false),
            if (!completed)
              _LockedAnalyticsCard(
                remainingStops: trip?.remainingStops,
                onGoHome: widget.onGoHome,
                onStartScan: widget.onStartScan,
              )
            else ...[
              if (provider.isLoading && report == null)
                const _LoadingReport()
              else ...[
                _ReportHero(report: report),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: provider.isLoading
                      ? null
                      : () => context.read<TripProvider>().syncLocalRecords(),
                  icon: provider.isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.cloud_sync_rounded, size: 20),
                  label: Text(
                    provider.isLoading ? 'Syncing...' : 'Sync to server',
                  ),
                ),
                const SizedBox(height: 22),
                const Center(
                  child: Text(
                    'Supplier collection summary',
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
                if (suppliers.isEmpty)
                  const _EmptyReport()
                else
                  ...suppliers.map((item) {
                    return _SupplierReportCard(
                      item: Map<String, dynamic>.from(item),
                    );
                  }),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _AnalyticsTitle extends StatelessWidget {
  const _AnalyticsTitle();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Analytics',
          style: TextStyle(
            color: Color(0xFF071426),
            fontSize: 30,
            fontWeight: FontWeight.w900,
            height: 1.0,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Final trip report and server sync',
          style: TextStyle(
            color: Color(0xFF73838B),
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _ReportHero extends StatelessWidget {
  final Map<String, dynamic>? report;

  const _ReportHero({required this.report});

  @override
  Widget build(BuildContext context) {
    final totalKg = (report?['totalKgCollected'] ?? 0).toDouble();
    final distance = (report?['routeDistanceKm'] ?? 0).toDouble();
    final duration = (report?['durationMinutes'] ?? 0).toDouble();
    final status = report?['status']?.toString() ?? 'Not loaded';

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
            color: const Color(0xFF003E34),
            child: Stack(
              children: [
                Positioned(
                  right: -18,
                  top: -18,
                  child: Icon(
                    Icons.insights_rounded,
                    size: 120,
                    color: Colors.white.withValues(alpha: 0.06),
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
                        Icons.assignment_turned_in_rounded,
                        color: Colors.white,
                        size: 31,
                      ),
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'Daily collection report',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Status: $status',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.84),
                        fontSize: 14,
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
              child: Column(
                children: [
                  Row(
                    children: [
                      _ReportMetric(
                        label: 'Collected',
                        value: '${totalKg.toStringAsFixed(1)} kg',
                      ),
                      const SizedBox(width: 10),
                      _ReportMetric(
                        label: 'Distance',
                        value: '${distance.toStringAsFixed(2)} km',
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _ReportMetric(
                    label: 'Duration',
                    value: '${duration.toStringAsFixed(1)} min',
                    fullWidth: true,
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

class _ReportMetric extends StatelessWidget {
  final String label;
  final String value;
  final bool fullWidth;

  const _ReportMetric({
    required this.label,
    required this.value,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
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
              fontWeight: FontWeight.w900,
              fontSize: 17,
            ),
          ),
        ],
      ),
    );

    if (fullWidth) return SizedBox(width: double.infinity, child: content);

    return Expanded(child: content);
  }
}

class _SupplierReportCard extends StatelessWidget {
  final Map<String, dynamic> item;

  const _SupplierReportCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final shortfall = item['shortfallWarning'] == true;
    final expected = (item['expectedTotalKg'] ?? 0).toDouble();
    final collected = (item['totalCollectedKg'] ?? 0).toDouble();

    return Padding(
      padding: const EdgeInsets.only(left: 28, bottom: 12),
      child: OverflowBox(
        alignment: Alignment.centerLeft,
        maxWidth: MediaQuery.of(context).size.width - 50,
        child: Container(
          width: MediaQuery.of(context).size.width - 50,
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: const Color(0xFF003E34),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: shortfall
                  ? const Color(0xFFFF8A1F)
                  : const Color(0xFFFFD166),
              shape: BoxShape.circle,
            ),
            child: Text(
              '${item['sequenceNo'] ?? '-'}',
              style: const TextStyle(
                color: Colors.white,
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
                  '${item['supplierCode']} • ${item['name']}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item['address']?.toString() ?? '',
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
                    _InfoPill(
                      icon: Icons.scale_rounded,
                      text: 'Collected ${collected.toStringAsFixed(1)} kg',
                    ),
                    _InfoPill(
                      icon: Icons.inventory_2_rounded,
                      text: 'Expected ${expected.toStringAsFixed(1)} kg',
                    ),
                    _InfoPill(
                      icon: Icons.check_circle_rounded,
                      text: item['status']?.toString() ?? '',
                    ),
                  ],
                ),
                if (shortfall) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE8CE),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.warning_rounded,
                          color: Color(0xFFC2410C),
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Shortfall: collected quantity is below expected amount.',
                            style: TextStyle(
                              color: Color(0xFF9A3412),
                              fontWeight: FontWeight.w900,
                              height: 1.25,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
          ),
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoPill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _LockedAnalyticsCard extends StatelessWidget {
  final int? remainingStops;
  final VoidCallback? onGoHome;
  final VoidCallback? onStartScan;

  const _LockedAnalyticsCard({
    required this.remainingStops,
    required this.onGoHome,
    required this.onStartScan,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF7F2),
                borderRadius: BorderRadius.circular(26),
              ),
              child: const Icon(
                Icons.lock_rounded,
                color: Color(0xFF005B49),
                size: 38,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Analytics locked',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF071426),
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              remainingStops == null
                  ? 'Complete all collection stops first.'
                  : '$remainingStops stops remaining. Complete the trip to unlock the final report.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF73838B),
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onGoHome,
                    icon: const Icon(Icons.home_rounded),
                    label: const Text('Home'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onStartScan,
                    icon: const Icon(Icons.qr_code_scanner_rounded),
                    label: const Text('Scan'),
                  ),
                ),
              ],
            ),
          ],
        ),
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
                color: isError ? const Color(0xFFE11D48) : const Color(0xFF005B49),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: isError ? const Color(0xFF9F1239) : const Color(0xFF005B49),
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

class _LoadingReport extends StatelessWidget {
  const _LoadingReport();

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

class _EmptyReport extends StatelessWidget {
  const _EmptyReport();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(22),
        child: Center(
          child: Text(
            'No report data available yet.',
            style: TextStyle(color: Color(0xFF73838B)),
          ),
        ),
      ),
    );
  }
}
