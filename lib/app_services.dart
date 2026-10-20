import 'services/history_store.dart';
import 'services/report_service.dart';
import 'services/vehicle_lookup_service.dart';

/// Long-lived services shared by all screens.
class AppServices {
  AppServices({
    VehicleLookupService? lookup,
    HistoryStore? history,
    ReportService? report,
  }) : lookup = lookup ?? VehicleLookupService(),
       history = history ?? HistoryStore(),
       report = report ?? ReportService();

  final VehicleLookupService lookup;
  final HistoryStore history;
  final ReportService report;
}
