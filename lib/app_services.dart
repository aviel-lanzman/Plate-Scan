import 'services/history_store.dart';
import 'services/report_photos.dart';
import 'services/report_service.dart';
import 'services/vehicle_lookup_service.dart';

/// Long-lived services shared by all screens.
class AppServices {
  AppServices({
    VehicleLookupService? lookup,
    HistoryStore? history,
    ReportService? report,
    ReportPhotos? photos,
  }) : lookup = lookup ?? VehicleLookupService(),
       history = history ?? HistoryStore(),
       report = report ?? ReportService(),
       photos = photos ?? ReportPhotos();

  final VehicleLookupService lookup;
  final HistoryStore history;
  final ReportService report;
  final ReportPhotos photos;
}
