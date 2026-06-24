class CollectionLocalModel {
  final String localRecordId;
  final String supplierCode;
  final double clearKg;
  final double colouredKg;
  final String condition;
  final String collectedAt;
  final int isSynced;

  CollectionLocalModel({
    required this.localRecordId,
    required this.supplierCode,
    required this.clearKg,
    required this.colouredKg,
    required this.condition,
    required this.collectedAt,
    required this.isSynced,
  });

  Map<String, dynamic> toMap() {
    return {
      'localRecordId': localRecordId,
      'supplierCode': supplierCode,
      'clearKg': clearKg,
      'colouredKg': colouredKg,
      'condition': condition,
      'collectedAt': collectedAt,
      'isSynced': isSynced,
    };
  }

  factory CollectionLocalModel.fromMap(Map<String, dynamic> map) {
    return CollectionLocalModel(
      localRecordId: map['localRecordId'],
      supplierCode: map['supplierCode'],
      clearKg: (map['clearKg'] as num).toDouble(),
      colouredKg: (map['colouredKg'] as num).toDouble(),
      condition: map['condition'],
      collectedAt: map['collectedAt'],
      isSynced: map['isSynced'],
    );
  }
}
