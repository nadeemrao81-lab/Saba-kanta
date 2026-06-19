// lib/models/weigh_record.dart

class WeighRecord {
  int? id;
  int serialNo;
  String partyName;
  String commodity;
  String driverName;
  String vehicleNo;
  double firstWeight;   // in Maunds
  double secondWeight;  // in Maunds
  double netWeight;     // Auto-calculated
  double ratePerMaund;
  double totalAmount;   // Auto-calculated
  String date;
  String time;

  WeighRecord({
    this.id,
    required this.serialNo,
    required this.partyName,
    required this.commodity,
    required this.driverName,
    required this.vehicleNo,
    required this.firstWeight,
    required this.secondWeight,
    required this.ratePerMaund,
    required this.date,
    required this.time,
  })  : netWeight = firstWeight - secondWeight,
        totalAmount = (firstWeight - secondWeight) * ratePerMaund;

  WeighRecord.full({
    this.id,
    required this.serialNo,
    required this.partyName,
    required this.commodity,
    required this.driverName,
    required this.vehicleNo,
    required this.firstWeight,
    required this.secondWeight,
    required this.netWeight,
    required this.ratePerMaund,
    required this.totalAmount,
    required this.date,
    required this.time,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'serialNo': serialNo,
      'partyName': partyName,
      'commodity': commodity,
      'driverName': driverName,
      'vehicleNo': vehicleNo,
      'firstWeight': firstWeight,
      'secondWeight': secondWeight,
      'netWeight': netWeight,
      'ratePerMaund': ratePerMaund,
      'totalAmount': totalAmount,
      'date': date,
      'time': time,
    };
  }

  factory WeighRecord.fromMap(Map<String, dynamic> map) {
    return WeighRecord.full(
      id: map['id'],
      serialNo: map['serialNo'],
      partyName: map['partyName'],
      commodity: map['commodity'],
      driverName: map['driverName'],
      vehicleNo: map['vehicleNo'],
      firstWeight: map['firstWeight'].toDouble(),
      secondWeight: map['secondWeight'].toDouble(),
      netWeight: map['netWeight'].toDouble(),
      ratePerMaund: map['ratePerMaund'].toDouble(),
      totalAmount: map['totalAmount'].toDouble(),
      date: map['date'],
      time: map['time'],
    );
  }

  String get formattedSerialNo => serialNo.toString().padLeft(8, '0');
}
