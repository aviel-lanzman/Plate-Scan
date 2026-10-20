/// Outcome of looking a plate up in the Ministry of Transport open data.
/// Declared in priority order: when a plate matches several datasets, the
/// earliest status wins.
enum PlateStatus {
  offRoad,
  inactive,
  licenseExpired,
  active,
  notFound,
  error;

  String get label => switch (this) {
    PlateStatus.offRoad => 'ירד מהכביש',
    PlateStatus.inactive => 'רכב לא פעיל',
    PlateStatus.licenseExpired => 'רישיון רכב פג תוקף',
    PlateStatus.active => 'רכב פעיל',
    PlateStatus.notFound => 'לא נמצא במאגר',
    PlateStatus.error => 'שגיאה בבדיקה',
  };

  String get description => switch (this) {
    PlateStatus.offRoad => 'הרכב מופיע במאגר משרד התחבורה ככלי רכב שירד מהכביש (ביטול סופי). אסור שייסע בכביש.',
    PlateStatus.inactive =>
      'הרכב רשום במאגר כלי הרכב הלא פעילים של משרד התחבורה.',
    PlateStatus.licenseExpired => 'הרכב פעיל, אבל תוקף רישיון הרכב שלו פג.',
    PlateStatus.active => 'הרכב רשום כפעיל במאגר משרד התחבורה.',
    PlateStatus.notFound =>
      'המספר לא נמצא באף מאגר. ייתכן שהמספר נקרא לא נכון, או שהלוחית חשודה.',
    PlateStatus.error =>
      'לא הצלחנו לבדוק את המספר מול המאגר. בדוק את החיבור לאינטרנט ונסה שוב.',
  };

  /// Statuses that justify an alert in continuous mode.
  bool get isAlert =>
      this == PlateStatus.offRoad || this == PlateStatus.inactive;
}

/// Result of the semi-manual check on the Israel Police stolen-vehicle page.
enum StolenCheckOutcome {
  stolen,
  clean,
  error;

  String get label => switch (this) {
    StolenCheckOutcome.stolen => 'מדווח כגנוב במשטרה',
    StolenCheckOutcome.clean => 'לא מופיע במאגר הרכבים הגנובים',
    StolenCheckOutcome.error => 'אתר המשטרה החזיר שגיאה',
  };
}

/// Registered vehicle details, used to let the user confirm that the car in
/// front of them matches the plate (a mismatch hints at a forged plate).
class VehicleInfo {
  const VehicleInfo({
    this.manufacturer,
    this.model,
    this.color,
    this.year,
    this.vehicleType,
    this.licenseValidUntil,
    this.cancelledOn,
  });

  /// Builds from a data.gov.il `datastore_search` record. Field names are the
  /// same across the Ministry of Transport vehicle datasets.
  factory VehicleInfo.fromRecord(Map<String, dynamic> record) => VehicleInfo(
    manufacturer: _text(record['tozeret_nm']),
    model: _text(record['kinuy_mishari']) ?? _text(record['degem_nm']),
    color: _text(record['tzeva_rechev']),
    year: _int(record['shnat_yitzur']),
    vehicleType: _text(record['sug_rechev_nm']),
    licenseValidUntil: _text(record['tokef_dt']),
    cancelledOn: _text(record['bitul_dt']),
  );

  factory VehicleInfo.fromJson(Map<String, dynamic> json) => VehicleInfo(
    manufacturer: json['manufacturer'] as String?,
    model: json['model'] as String?,
    color: json['color'] as String?,
    year: json['year'] as int?,
    vehicleType: json['vehicleType'] as String?,
    licenseValidUntil: json['licenseValidUntil'] as String?,
    cancelledOn: json['cancelledOn'] as String?,
  );

  final String? manufacturer;
  final String? model;
  final String? color;
  final int? year;
  final String? vehicleType;

  /// `yyyy-mm-dd`, active registry only.
  final String? licenseValidUntil;

  /// `yyyy-mm-dd`, off-road dataset only.
  final String? cancelledOn;

  /// e.g. "פיג'ו צרפת 3008, שנהב לבן, 2023".
  String get summary {
    final name = [manufacturer, model].whereType<String>().join(' ');
    return [
      name,
      color,
      year?.toString(),
    ].whereType<String>().where((s) => s.isNotEmpty).join(', ');
  }

  /// Fills fields missing here with values from [other].
  VehicleInfo mergedWith(VehicleInfo other) => VehicleInfo(
    manufacturer: manufacturer ?? other.manufacturer,
    model: model ?? other.model,
    color: color ?? other.color,
    year: year ?? other.year,
    vehicleType: vehicleType ?? other.vehicleType,
    licenseValidUntil: licenseValidUntil ?? other.licenseValidUntil,
    cancelledOn: cancelledOn ?? other.cancelledOn,
  );

  Map<String, dynamic> toJson() => {
    'manufacturer': manufacturer,
    'model': model,
    'color': color,
    'year': year,
    'vehicleType': vehicleType,
    'licenseValidUntil': licenseValidUntil,
    'cancelledOn': cancelledOn,
  };

  static String? _text(Object? value) {
    final s = value?.toString().trim();
    return (s == null || s.isEmpty) ? null : s;
  }

  static int? _int(Object? value) =>
      value is int ? value : int.tryParse(value?.toString() ?? '');
}

class VehicleResult {
  const VehicleResult({
    required this.plate,
    required this.status,
    required this.checkedAt,
    this.info,
    this.stolenCheck,
  });

  factory VehicleResult.fromJson(Map<String, dynamic> json) => VehicleResult(
    plate: json['plate'] as String,
    status: PlateStatus.values.byName(json['status'] as String),
    checkedAt: DateTime.parse(json['checkedAt'] as String),
    info: json['info'] == null
        ? null
        : VehicleInfo.fromJson(json['info'] as Map<String, dynamic>),
    stolenCheck: json['stolenCheck'] == null
        ? null
        : StolenCheckOutcome.values.byName(json['stolenCheck'] as String),
  );

  /// Digits only, e.g. "1234567".
  final String plate;
  final PlateStatus status;
  final DateTime checkedAt;
  final VehicleInfo? info;
  final StolenCheckOutcome? stolenCheck;

  bool get needsReport =>
      status.isAlert || stolenCheck == StolenCheckOutcome.stolen;

  VehicleResult withStolenCheck(StolenCheckOutcome outcome) => VehicleResult(
    plate: plate,
    status: status,
    checkedAt: checkedAt,
    info: info,
    stolenCheck: outcome,
  );

  Map<String, dynamic> toJson() => {
    'plate': plate,
    'status': status.name,
    'checkedAt': checkedAt.toIso8601String(),
    'info': info?.toJson(),
    'stolenCheck': stolenCheck?.name,
  };
}
