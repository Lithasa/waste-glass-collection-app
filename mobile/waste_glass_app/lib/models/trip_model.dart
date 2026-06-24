class TripModel {
  final int id;
  final String tripDate;
  final String status;
  final double totalRouteDistanceKm;
  final int remainingStops;
  final List<TripStopModel> stops;

  TripModel({
    required this.id,
    required this.tripDate,
    required this.status,
    required this.totalRouteDistanceKm,
    required this.remainingStops,
    required this.stops,
  });

  factory TripModel.fromJson(Map<String, dynamic> json) {
    final source = _unwrap(json);
    final stopsJson = _findFirstListDeep(source, const [
      'stops',
      'tripStops',
      'trip_stops',
      'routeStops',
      'route',
    ]);

    return TripModel(
      id: _asInt(_firstValue(source, const ['id', 'tripId', 'tripID'])),
      tripDate: _asString(_firstValue(source, const ['tripDate', 'date'])),
      status: _asString(_firstValue(source, const ['status', 'tripStatus'])),
      totalRouteDistanceKm: _asDouble(
        _firstValue(source, const [
          'totalRouteDistanceKm',
          'routeDistanceKm',
          'totalDistanceKm',
          'distanceKm',
        ]),
      ),
      remainingStops: _asInt(
        _firstValue(source, const ['remainingStops', 'remainingStopCount']),
      ),
      stops: stopsJson.map(TripStopModel.fromJson).toList(),
    );
  }

  /// Use this list for UI rendering and scanner flow.
  /// If the backend returns the trip summary but the stop array is empty or
  /// missing, this fallback keeps the demo route visible and usable.
  List<TripStopModel> get displayStops {
    if (stops.isNotEmpty) return stops;
    return demoStopsForRemaining(remainingStops: remainingStops);
  }

  TripStopModel? get nextStop {
    for (final stop in displayStops) {
      if (stop.status.toLowerCase() == 'next') return stop;
    }
    return null;
  }

  bool get isCompleted =>
      remainingStops == 0 || status.toLowerCase() == 'completed';

  static List<TripStopModel> demoStopsForRemaining({required int remainingStops}) {
    final safeRemaining = remainingStops.clamp(0, 5);
    final collectedCount = (5 - safeRemaining).clamp(0, 5);

    final suppliers = <SupplierModel>[
      SupplierModel(
        supplierCode: 'SUP003',
        name: 'Maradana Glass Store',
        address: 'Maradana, Colombo',
        latitude: 6.9285,
        longitude: 79.8648,
        expectedClearKg: 50,
        expectedColouredKg: 30,
        expectedTotalKg: 80,
        barcodeValue: 'SUP003',
      ),
      SupplierModel(
        supplierCode: 'SUP004',
        name: 'Borella Recycling Supplier',
        address: 'Borella, Colombo',
        latitude: 6.9147,
        longitude: 79.8778,
        expectedClearKg: 45,
        expectedColouredKg: 35,
        expectedTotalKg: 80,
        barcodeValue: 'SUP004',
      ),
      SupplierModel(
        supplierCode: 'SUP005',
        name: 'Narahenpita Bottle Collection',
        address: 'Narahenpita, Colombo',
        latitude: 6.8914,
        longitude: 79.8792,
        expectedClearKg: 40,
        expectedColouredKg: 40,
        expectedTotalKg: 80,
        barcodeValue: 'SUP005',
      ),
      SupplierModel(
        supplierCode: 'SUP001',
        name: 'Pettah Bottle Supplier',
        address: 'Pettah, Colombo',
        latitude: 6.9367,
        longitude: 79.8498,
        expectedClearKg: 30,
        expectedColouredKg: 30,
        expectedTotalKg: 60,
        barcodeValue: 'SUP001',
      ),
      SupplierModel(
        supplierCode: 'SUP002',
        name: 'Fort Hotel Waste Point',
        address: 'Fort, Colombo',
        latitude: 6.9339,
        longitude: 79.8428,
        expectedClearKg: 50,
        expectedColouredKg: 50,
        expectedTotalKg: 100,
        barcodeValue: 'SUP002',
      ),
    ];

    final distances = <double>[0.42, 1.90, 2.79, 6.16, 0.80];

    return List.generate(suppliers.length, (index) {
      String status;
      if (index < collectedCount) {
        status = 'Collected';
      } else if (index == collectedCount && safeRemaining > 0) {
        status = 'Next';
      } else {
        status = 'Pending';
      }

      return TripStopModel(
        id: index + 1,
        sequenceNo: index + 1,
        status: status,
        distanceFromPreviousKm: distances[index],
        supplier: suppliers[index],
      );
    });
  }
}

class TripStopModel {
  final int id;
  final int sequenceNo;
  final String status;
  final double distanceFromPreviousKm;
  final SupplierModel supplier;

  TripStopModel({
    required this.id,
    required this.sequenceNo,
    required this.status,
    required this.distanceFromPreviousKm,
    required this.supplier,
  });

  factory TripStopModel.fromJson(Map<String, dynamic> json) {
    final supplierJson = _firstMap(json, const [
      'supplier',
      'Supplier',
      'supplierDetails',
    ]);

    return TripStopModel(
      id: _asInt(_firstValue(json, const ['id', 'tripStopId', 'tripStopID'])),
      sequenceNo: _asInt(
        _firstValue(json, const ['sequenceNo', 'sequence', 'orderNo', 'order']),
      ),
      status: _asString(_firstValue(json, const ['status', 'stopStatus'])),
      distanceFromPreviousKm: _asDouble(
        _firstValue(json, const [
          'distanceFromPreviousKm',
          'distanceKm',
          'distance',
        ]),
      ),
      supplier: SupplierModel.fromJson(supplierJson),
    );
  }
}

class SupplierModel {
  final String supplierCode;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final double expectedClearKg;
  final double expectedColouredKg;
  final double expectedTotalKg;
  final String barcodeValue;

  SupplierModel({
    required this.supplierCode,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.expectedClearKg,
    required this.expectedColouredKg,
    required this.expectedTotalKg,
    required this.barcodeValue,
  });

  factory SupplierModel.fromJson(Map<String, dynamic> json) {
    final supplierCode = _asString(
      _firstValue(json, const ['supplierCode', 'code', 'idCode']),
    );
    final barcode = _asString(
      _firstValue(json, const ['barcodeValue', 'barcode', 'barcodeId']),
    );

    return SupplierModel(
      supplierCode: supplierCode,
      name: _asString(_firstValue(json, const ['name', 'supplierName'])),
      address: _asString(_firstValue(json, const ['address', 'location'])),
      latitude: _asDouble(_firstValue(json, const ['latitude', 'lat'])),
      longitude: _asDouble(_firstValue(json, const ['longitude', 'lng', 'lon'])),
      expectedClearKg: _asDouble(
        _firstValue(json, const ['expectedClearKg', 'clearKgExpected']),
      ),
      expectedColouredKg: _asDouble(
        _firstValue(json, const ['expectedColouredKg', 'colouredKgExpected']),
      ),
      expectedTotalKg: _asDouble(
        _firstValue(json, const [
          'expectedTotalKg',
          'expectedKg',
          'expectedTotal',
        ]),
      ),
      barcodeValue: barcode.isNotEmpty ? barcode : supplierCode,
    );
  }
}

Map<String, dynamic> _unwrap(Map<String, dynamic> json) {
  for (final key in const ['payload', 'data', 'trip', 'result']) {
    final value = json[key];
    if (value is Map) return Map<String, dynamic>.from(value);
  }
  return json;
}

Object? _firstValue(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    if (json.containsKey(key) && json[key] != null) return json[key];
  }
  for (final entry in json.entries) {
    final value = entry.value;
    if (value is Map) {
      final nested = _firstValue(Map<String, dynamic>.from(value), keys);
      if (nested != null) return nested;
    }
  }
  return null;
}

Map<String, dynamic> _firstMap(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is Map) return Map<String, dynamic>.from(value);
  }
  return <String, dynamic>{};
}

List<Map<String, dynamic>> _findFirstListDeep(
  Map<String, dynamic> json,
  List<String> keys,
) {
  for (final key in keys) {
    final value = json[key];
    if (value is List) {
      return value
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
  }

  for (final value in json.values) {
    if (value is Map) {
      final nested = _findFirstListDeep(Map<String, dynamic>.from(value), keys);
      if (nested.isNotEmpty) return nested;
    }
  }

  return <Map<String, dynamic>>[];
}

int _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _asDouble(Object? value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

String _asString(Object? value) => value?.toString() ?? '';
