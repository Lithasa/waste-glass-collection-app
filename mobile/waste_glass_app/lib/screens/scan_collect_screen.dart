import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/collection_local_model.dart';
import '../models/trip_model.dart';
import '../providers/trip_provider.dart';

class ScanCollectScreen extends StatefulWidget {
  final VoidCallback? onCompleted;
  final VoidCallback? onGoHome;

  const ScanCollectScreen({super.key, this.onCompleted, this.onGoHome});

  @override
  State<ScanCollectScreen> createState() => _ScanCollectScreenState();
}

class _ScanCollectScreenState extends State<ScanCollectScreen> {
  MobileScannerController _scannerController = MobileScannerController();
  final TextEditingController _clearKgController = TextEditingController();
  final TextEditingController _colouredKgController = TextEditingController();
  final TextEditingController _conditionController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _hasScanned = false;
  bool _isVerified = false;
  String? _scannedCode;
  String? _scanMessage;
  String? _activeSupplierCode;
  int _scannerVersion = 0;

  @override
  void dispose() {
    _scannerController.dispose();
    _clearKgController.dispose();
    _colouredKgController.dispose();
    _conditionController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _replaceScannerController() {
    final oldController = _scannerController;
    _scannerController = MobileScannerController();
    _scannerVersion++;
    oldController.dispose();
  }

  void _resetForStop(TripStopModel? stop) {
    final newCode = stop?.supplier.supplierCode;
    if (_activeSupplierCode == newCode) return;

    setState(() {
      _activeSupplierCode = newCode;
      _hasScanned = false;
      _isVerified = false;
      _scannedCode = null;
      _scanMessage = null;
      _clearKgController.clear();
      _colouredKgController.clear();
      _conditionController.clear();
      _replaceScannerController();
    });
  }

  void _restartScannerForSameStop() {
    setState(() {
      _hasScanned = false;
      _isVerified = false;
      _scannedCode = null;
      _scanMessage = null;
      _replaceScannerController();
    });
  }

  void _handleBarcode(String value) async {
    if (_hasScanned) return;

    final tripProvider = context.read<TripProvider>();

    setState(() {
      _hasScanned = true;
      _scannedCode = value;
    });

    await _scannerController.stop();

    if (!mounted) return;

    final isCorrect = tripProvider.isCorrectBarcode(value);

    if (isCorrect) {
      setState(() {
        _isVerified = true;
        _scanMessage = 'Correct supplier verified. Collection form unlocked.';
      });

      await Future.delayed(const Duration(milliseconds: 320));
      if (!mounted) return;

      _scrollController.animateTo(
        360,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    } else {
      setState(() {
        _isVerified = false;
        _scanMessage = 'Wrong barcode. Expected current stop, scanned $value.';
      });

      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;

      setState(() {
        _hasScanned = false;
        _scannedCode = null;
        _scanMessage = null;
      });

      await _scannerController.start();
    }
  }

  Future<void> _submitCollection(TripStopModel stop) async {
    final clearKg = double.tryParse(_clearKgController.text.trim());
    final colouredKg = double.tryParse(_colouredKgController.text.trim());
    final condition = _conditionController.text.trim();

    if (!_isVerified) {
      _showSnack('Scan and verify the correct supplier first.', isError: true);
      return;
    }

    if (clearKg == null || clearKg < 0) {
      _showSnack('Enter a valid clear glass quantity.', isError: true);
      return;
    }

    if (colouredKg == null || colouredKg < 0) {
      _showSnack('Enter a valid coloured glass quantity.', isError: true);
      return;
    }

    if (condition.isEmpty) {
      _showSnack('Enter the glass condition.', isError: true);
      return;
    }

    final record = CollectionLocalModel(
      localRecordId: const Uuid().v4(),
      supplierCode: stop.supplier.supplierCode,
      clearKg: clearKg,
      colouredKg: colouredKg,
      condition: condition,
      collectedAt: DateTime.now().toUtc().toIso8601String(),
      isSynced: 0,
    );

    await context.read<TripProvider>().saveAndSubmitCollection(record);

    if (!mounted) return;

    final provider = context.read<TripProvider>();

    if (provider.errorMessage != null) {
      _showSnack(provider.errorMessage!, isError: true);
      return;
    }

    _showSnack('Collection confirmed successfully.', isError: false);

    await Future.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;

    final completed = provider.trip?.isCompleted == true;

    if (completed) {
      widget.onCompleted?.call();
    } else {
      setState(() {
        _activeSupplierCode = null;
      });
    }
  }

  void _showSnack(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isError
            ? const Color(0xFFE11D48)
            : const Color(0xFF005B49),
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TripProvider>();
    final stop = provider.trip?.nextStop;

    WidgetsBinding.instance.addPostFrameCallback((_) => _resetForStop(stop));

    return SafeArea(
      child: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(22, 16, 22, 92),
        children: [
          const _ScreenTitle(),
          const SizedBox(height: 14),
          if (stop == null)
            _NoStopCard(onGoHome: widget.onGoHome)
          else ...[
            _ScanHeroCard(stop: stop),
            const SizedBox(height: 14),
            _ScannerCard(
              key: ValueKey('scanner_${_activeSupplierCode}_$_scannerVersion'),
              controller: _scannerController,
              isVerified: _isVerified,
              scannedCode: _scannedCode,
              scanMessage: _scanMessage,
              onDetect: _handleBarcode,
              onScanAgain: _restartScannerForSameStop,
            ),
            const SizedBox(height: 14),
            _CollectionForm(
              isUnlocked: _isVerified,
              clearKgController: _clearKgController,
              colouredKgController: _colouredKgController,
              conditionController: _conditionController,
              expectedText:
                  '${stop.supplier.expectedClearKg.toStringAsFixed(0)} kg clear + ${stop.supplier.expectedColouredKg.toStringAsFixed(0)} kg coloured expected',
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: provider.isLoading
                  ? null
                  : () => _submitCollection(stop),
              icon: provider.isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.check_circle_rounded, size: 20),
              label: Text(
                provider.isLoading ? 'Submitting...' : 'Confirm collection',
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ScreenTitle extends StatelessWidget {
  const _ScreenTitle();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Scan',
          style: TextStyle(
            color: Color(0xFF071426),
            fontSize: 30,
            fontWeight: FontWeight.w900,
            height: 1.0,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Verify supplier barcode and collect glass',
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

class _ScanHeroCard extends StatelessWidget {
  final TripStopModel stop;

  const _ScanHeroCard({required this.stop});

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFF005B49),
        borderRadius: BorderRadius.circular(31),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF003E34).withValues(alpha: 0.18),
            blurRadius: 22,
            offset: const Offset(0, 13),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            color: const Color(0xFF003E34),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD166),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${stop.sequenceNo}',
                    style: const TextStyle(
                      color: Color(0xFF003E34),
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Next destination',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.70),
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        stop.supplier.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                          height: 1.12,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        stop.supplier.address,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.78),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ClipPath(
            clipper: _WaveClipper(),
            child: Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 23, 20, 14),
              child: Text(
                'Barcode ID: ${stop.supplier.barcodeValue}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF005B49),
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
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
    path.moveTo(0, 16);
    path.quadraticBezierTo(size.width * 0.25, 0, size.width * 0.50, 16);
    path.quadraticBezierTo(size.width * 0.75, 32, size.width, 16);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _ScannerCard extends StatelessWidget {
  final MobileScannerController controller;
  final bool isVerified;
  final String? scannedCode;
  final String? scanMessage;
  final void Function(String value) onDetect;
  final VoidCallback onScanAgain;

  const _ScannerCard({
    super.key,
    required this.controller,
    required this.isVerified,
    required this.scannedCode,
    required this.scanMessage,
    required this.onDetect,
    required this.onScanAgain,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          if (isVerified)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              color: const Color(0xFF003E34),
              child: Column(
                children: [
                  Container(
                    width: 78,
                    height: 78,
                    decoration: BoxDecoration(
                      color: const Color(0xFF64E863),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: const Icon(
                      Icons.verified_rounded,
                      color: Color(0xFF003E34),
                      size: 42,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Supplier verified',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    scanMessage ?? 'Collection form is unlocked.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              height: 245,
              color: Colors.black,
              child: Stack(
                children: [
                  MobileScanner(
                    key: ValueKey(controller.hashCode),
                    controller: controller,
                    onDetect: (capture) {
                      final barcode = capture.barcodes.firstOrNull;
                      final value = barcode?.rawValue;

                      if (value == null || value.trim().isEmpty) return;

                      onDetect(value.trim());
                    },
                  ),
                  Center(
                    child: Container(
                      width: 205,
                      height: 112,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFF64E863),
                          width: 3,
                        ),
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(
                  isVerified
                      ? Icons.check_circle_rounded
                      : Icons.qr_code_scanner_rounded,
                  color: isVerified
                      ? const Color(0xFF005B49)
                      : const Color(0xFF73838B),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isVerified
                        ? 'Correct barcode scanned. Enter quantities below.'
                        : 'Scan the supplier barcode. Wrong ID is blocked.',
                    style: const TextStyle(
                      color: Color(0xFF34464D),
                      fontWeight: FontWeight.w800,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (scannedCode != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF7F2),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(
                        'Scanned: $scannedCode',
                        style: const TextStyle(
                          color: Color(0xFF071426),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    onPressed: onScanAgain,
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFEAF7F2),
                      foregroundColor: const Color(0xFF005B49),
                    ),
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _CollectionForm extends StatelessWidget {
  final bool isUnlocked;
  final TextEditingController clearKgController;
  final TextEditingController colouredKgController;
  final TextEditingController conditionController;
  final String expectedText;

  const _CollectionForm({
    required this.isUnlocked,
    required this.clearKgController,
    required this.colouredKgController,
    required this.conditionController,
    required this.expectedText,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 220),
      opacity: isUnlocked ? 1 : 0.48,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: IgnorePointer(
            ignoring: !isUnlocked,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Collection quantity',
                  style: TextStyle(
                    color: Color(0xFF071426),
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  expectedText,
                  style: const TextStyle(
                    color: Color(0xFF73838B),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: clearKgController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Clear glass (kg)',
                    prefixIcon: Icon(Icons.scale_rounded),
                  ),
                ),
                const SizedBox(height: 11),
                TextField(
                  controller: colouredKgController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Coloured glass (kg)',
                    prefixIcon: Icon(Icons.scale_rounded),
                  ),
                ),
                const SizedBox(height: 11),
                TextField(
                  controller: conditionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Condition',
                    hintText: 'Example: Good / Mixed / Needs sorting',
                    prefixIcon: Icon(Icons.notes_rounded),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NoStopCard extends StatelessWidget {
  final VoidCallback? onGoHome;

  const _NoStopCard({required this.onGoHome});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF005B49),
              size: 58,
            ),
            const SizedBox(height: 12),
            const Text(
              'All suppliers collected',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF071426),
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Open Analytics to view the final report and sync to server.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF73838B),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onGoHome,
              icon: const Icon(Icons.home_rounded),
              label: const Text('Back to Home'),
            ),
          ],
        ),
      ),
    );
  }
}
