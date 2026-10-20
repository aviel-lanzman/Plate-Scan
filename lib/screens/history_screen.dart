import 'package:flutter/material.dart';

import '../app_services.dart';
import '../models/vehicle_result.dart';
import '../util/format.dart';
import '../widgets/plate_result_tile.dart';
import 'result_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, required this.services});

  final AppServices services;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<VehicleResult>> _entries = widget.services.history.load();

  void _reload() => setState(() => _entries = widget.services.history.load());

  Future<void> _clear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('למחוק את ההיסטוריה?'),
        content: const Text('כל הבדיקות השמורות במכשיר יימחקו.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ביטול'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('מחק'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await widget.services.history.clear();
    _reload();
  }

  Future<void> _open(VehicleResult entry) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ResultScreen(
          services: widget.services,
          plate: entry.plate,
          initial: entry,
        ),
      ),
    );
    if (mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('היסטוריית בדיקות'),
        actions: [
          IconButton(
            tooltip: 'מחק היסטוריה',
            icon: const Icon(Icons.delete_sweep),
            onPressed: _clear,
          ),
        ],
      ),
      body: FutureBuilder<List<VehicleResult>>(
        future: _entries,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('לא ניתן לטעון את ההיסטוריה'),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _reload,
                    icon: const Icon(Icons.refresh),
                    label: const Text('נסה שוב'),
                  ),
                ],
              ),
            );
          }
          final entries = snapshot.data;
          if (entries == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (entries.isEmpty) {
            return const Center(child: Text('עדיין לא נבדקו רכבים'));
          }
          return ListView.separated(
            itemCount: entries.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final e = entries[i];
              return PlateResultTile(
                plate: e.plate,
                status: e.status,
                stolen: e.stolenCheck,
                summary: e.info?.summary,
                time: formatDateTime(e.checkedAt),
                onTap: () => _open(e),
              );
            },
          );
        },
      ),
    );
  }
}
