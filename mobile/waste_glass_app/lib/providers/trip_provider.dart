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

      trip = await _apiService.getTodayTrip();
      successMessage = 'Collection saved locally and submitted to backend';
    } catch (e) {
      errorMessage =
          'Saved locally. Backend submission failed: ${e.toString()}';
    }

    isLoading = false;
    notifyListeners();
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
