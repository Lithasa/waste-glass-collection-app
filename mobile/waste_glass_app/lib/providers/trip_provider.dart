import 'package:flutter/material.dart';

import '../models/collection_local_model.dart';
import '../models/trip_model.dart';
import '../services/api_service.dart';
import '../services/local_db_service.dart';

class TripProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final LocalDbService _localDbService = LocalDbService.instance;

  TripModel? trip;
  Map<String, dynamic>? report;

  bool isLoading = false;
  String? errorMessage;
  String? successMessage;

  Future<void> loadTodayTrip() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      trip = await _apiService.getTodayTrip();
    } catch (e) {
      errorMessage = e.toString();
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> resetDemoTrip() async {
    isLoading = true;
    errorMessage = null;
    successMessage = null;
    report = null;
    notifyListeners();

    try {
      await _localDbService.clearAll();
      await _apiService.resetDemoTrip();
      trip = await _apiService.getTodayTrip();
      successMessage = 'Demo trip reset successfully';
    } catch (e) {
      errorMessage = e.toString();
    }

    isLoading = false;
    notifyListeners();
  }

  bool isCorrectBarcode(String scannedValue) {
    final nextStop = trip?.nextStop;
    if (nextStop == null) return false;

    return scannedValue.trim().toUpperCase() ==
        nextStop.supplier.barcodeValue.trim().toUpperCase();
  }

  Future<void> saveAndSubmitCollection(CollectionLocalModel record) async {
    isLoading = true;
    errorMessage = null;
    successMessage = null;
    notifyListeners();

    try {
      await _localDbService.insertCollection(record);

      await _apiService.submitCollection(
        supplierCode: record.supplierCode,
        clearKg: record.clearKg,
        colouredKg: record.colouredKg,
        condition: record.condition,
        localRecordId: record.localRecordId,
        collectedAt: record.collectedAt,
      );

      await _localDbService.markAsSynced(record.localRecordId);

      try {
        trip = await _apiService.getTodayTrip();
      } catch (_) {
        _advanceLocalTripProgress();
      }

      successMessage = 'Collection saved locally and submitted to backend';
    } catch (e) {
      // Offline-first fallback: the record is safe in SQLite and the UI still
      // advances so the demo can continue. Use Sync to server after the backend
      // connection is stable again.
      _advanceLocalTripProgress();
      successMessage = 'Saved locally. Backend sync pending';
    }

    isLoading = false;
    notifyListeners();
  }

  void _advanceLocalTripProgress() {
    final currentTrip = trip;
    final currentRemaining = currentTrip?.remainingStops ?? 5;
    final nextRemaining = (currentRemaining - 1).clamp(0, 5).toInt();

    trip = TripModel(
      id: currentTrip?.id ?? 0,
      tripDate: currentTrip?.tripDate ?? DateTime.now().toIso8601String(),
      status: nextRemaining == 0 ? 'Completed' : 'InProgress',
      totalRouteDistanceKm:
          currentTrip?.totalRouteDistanceKm == 0 ||
              currentTrip?.totalRouteDistanceKm == null
          ? 12.07
          : currentTrip!.totalRouteDistanceKm,
      remainingStops: nextRemaining,
      stops: TripModel.demoStopsForRemaining(remainingStops: nextRemaining),
    );
  }

  Future<void> loadReport() async {
    isLoading = true;
    errorMessage = null;
    successMessage = null;
    notifyListeners();

    try {
      report = await _apiService.getTodayReport();
    } catch (e) {
      errorMessage = e.toString();
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> syncLocalRecords() async {
    isLoading = true;
    errorMessage = null;
    successMessage = null;
    notifyListeners();

    try {
      final localRecords = await _localDbService.getAllCollections();

      if (localRecords.isEmpty) {
        successMessage = 'No local collection records found to sync';
      } else {
        await _apiService.syncCollections(localRecords);
        await _localDbService.markAllAsSynced();
        successMessage = 'Final sync completed successfully';
      }

      trip = await _apiService.getTodayTrip();
      if (trip?.isCompleted == true) {
        report = await _apiService.getTodayReport();
      }
    } catch (e) {
      errorMessage = 'Sync failed. Data is still safe locally: ${e.toString()}';
    }

    isLoading = false;
    notifyListeners();
  }
}
