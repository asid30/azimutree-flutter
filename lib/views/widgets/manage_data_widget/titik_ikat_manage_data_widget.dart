import 'package:azimutree/data/models/cluster_model.dart';
import 'package:azimutree/data/models/titik_ikat_model.dart';
import 'package:azimutree/data/notifiers/notifiers.dart';
import 'package:azimutree/data/notifiers/titik_ikat_notifier.dart';
import 'package:azimutree/views/widgets/alert_dialog_widget/alert_confirmation_widget.dart';
import 'package:azimutree/views/widgets/manage_data_widget/dialog_titik_ikat_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class TitikIkatManageDataWidget extends StatelessWidget {
  const TitikIkatManageDataWidget({
    super.key,
    required this.cluster,
    required this.clusters,
    required this.titikIkatData,
    required this.titikIkatNotifier,
  });

  final ClusterModel cluster;
  final List<ClusterModel> clusters;
  final List<TitikIkatModel> titikIkatData;
  final TitikIkatNotifier titikIkatNotifier;

  Future<void> _edit(BuildContext context, TitikIkatModel titikIkat) async {
    await showDialog<TitikIkatModel>(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => DialogTitikIkatWidget(
            clusters: clusters,
            titikIkatNotifier: titikIkatNotifier,
            titikIkat: titikIkat,
          ),
    );
  }

  Future<void> _delete(BuildContext context, TitikIkatModel titikIkat) async {
    if (titikIkat.id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertConfirmationWidget(
            title: 'Hapus Titik Ikat?',
            message: 'Titik Ikat "${titikIkat.nama}" akan dihapus.',
            confirmText: 'Hapus',
            cancelText: 'Batal',
          ),
    );
    if (confirmed != true) return;
    await titikIkatNotifier.deleteTitikIkat(titikIkat.id!);
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Titik Ikat dihapus')));
    }
  }

  TableRow _row(String label, String value, Color color) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 3, right: 8),
          child: Text(label, style: TextStyle(color: color)),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Text(': $value', style: TextStyle(color: color)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isLightModeNotifier,
      builder: (context, isLight, _) {
        final isDark = !isLight;
        final foreground = isDark ? Colors.white : Colors.black87;
        final sectionColor =
            isDark
                ? const Color.fromARGB(255, 36, 67, 42)
                : const Color.fromARGB(240, 180, 216, 187);
        final cardColor =
            isDark
                ? const Color.fromARGB(255, 25, 48, 30)
                : const Color.fromARGB(239, 188, 228, 196);

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: sectionColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Data Titik Ikat',
                style: TextStyle(
                  color: foreground,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (titikIkatData.isEmpty)
                Text(
                  'Tidak ada Titik Ikat untuk klaster ini',
                  style: TextStyle(color: foreground),
                )
              else
                for (final titikIkat in titikIkatData)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Slidable(
                      key: ValueKey('titik_ikat_${titikIkat.id}'),
                      startActionPane: ActionPane(
                        motion: const DrawerMotion(),
                        extentRatio: 0.28,
                        children: [
                          SlidableAction(
                            onPressed: (_) => _edit(context, titikIkat),
                            backgroundColor:
                                isDark
                                    ? const Color.fromARGB(255, 54, 92, 50)
                                    : Colors.blue.shade100,
                            foregroundColor:
                                isDark ? Colors.white : Colors.blue.shade900,
                            icon: Icons.edit,
                            label: 'Edit',
                          ),
                        ],
                      ),
                      endActionPane: ActionPane(
                        motion: const DrawerMotion(),
                        extentRatio: 0.28,
                        children: [
                          SlidableAction(
                            onPressed: (_) => _delete(context, titikIkat),
                            backgroundColor:
                                isDark
                                    ? const Color.fromARGB(255, 98, 32, 32)
                                    : Colors.red.shade100,
                            foregroundColor:
                                isDark ? Colors.white : Colors.red.shade900,
                            icon: Icons.delete,
                            label: 'Hapus',
                          ),
                        ],
                      ),
                      child: Card(
                        margin: EdgeInsets.zero,
                        color: cardColor,
                        child: ExpansionTile(
                          iconColor: foreground,
                          collapsedIconColor: foreground,
                          leading: Icon(Icons.flag, color: foreground),
                          title: Text(
                            titikIkat.nama,
                            style: TextStyle(
                              color: foreground,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            '${titikIkat.azimutKePlot1.toStringAsFixed(1)}° • '
                            '${titikIkat.jarakKePlot1M.toStringAsFixed(1)} m ke P1',
                            style: TextStyle(color: foreground),
                          ),
                          childrenPadding: const EdgeInsets.fromLTRB(
                            16,
                            0,
                            16,
                            14,
                          ),
                          children: [
                            Table(
                              columnWidths: const {
                                0: FlexColumnWidth(1.1),
                                1: FlexColumnWidth(1.9),
                              },
                              children: [
                                _row(
                                  'Jenis',
                                  titikIkat.jenis ?? '-',
                                  foreground,
                                ),
                                _row(
                                  'Azimut ke P1',
                                  '${titikIkat.azimutKePlot1.toStringAsFixed(1)}°',
                                  foreground,
                                ),
                                _row(
                                  'Jarak ke P1',
                                  '${titikIkat.jarakKePlot1M.toStringAsFixed(2)} m',
                                  foreground,
                                ),
                                _row(
                                  'Latitude',
                                  titikIkat.latitude?.toStringAsFixed(6) ?? '-',
                                  foreground,
                                ),
                                _row(
                                  'Longitude',
                                  titikIkat.longitude?.toStringAsFixed(6) ??
                                      '-',
                                  foreground,
                                ),
                                _row(
                                  'Altitude',
                                  titikIkat.altitude == null
                                      ? '-'
                                      : '${titikIkat.altitude} m',
                                  foreground,
                                ),
                                _row(
                                  'Keterangan',
                                  titikIkat.keterangan ?? '-',
                                  foreground,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
            ],
          ),
        );
      },
    );
  }
}
