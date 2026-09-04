import 'package:azimutree/data/models/cluster_model.dart';
import 'package:azimutree/data/models/plot_model.dart';
import 'package:azimutree/data/models/titik_ikat_model.dart';
import 'package:azimutree/data/notifiers/notifiers.dart';
import 'package:azimutree/data/notifiers/titik_ikat_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:azimutree/services/gdrive_thumbnail_service.dart';

class TitikIkatManageDataWidget extends StatelessWidget {
  const TitikIkatManageDataWidget({
    super.key,
    required this.cluster,
    required this.clusters,
    required this.plots,
    required this.titikIkatData,
    required this.titikIkatNotifier,
  });

  final ClusterModel cluster;
  final List<ClusterModel> clusters;
  final List<PlotModel> plots;
  final List<TitikIkatModel> titikIkatData;
  final TitikIkatNotifier titikIkatNotifier;

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

  void _trackLocation(BuildContext context, TitikIkatModel titikIkat) {
    if (titikIkat.latitude == null || titikIkat.longitude == null) return;
    selectedPageNotifier.value = 'location_map_page';
    selectedTreeNotifier.value = null;
    selectedTreePlotNotifier.value = null;
    selectedTreeClusterNotifier.value = null;
    selectedPlotNotifier.value = null;
    selectedPlotClusterNotifier.value = null;
    selectedCentroidNotifier.value = null;
    selectedMarkerScreenOffsetNotifier.value = null;
    selectedLocationFromSearchNotifier.value = false;
    isFollowingUserLocationNotifier.value = false;
    preserveZoomOnNextCenterNotifier.value = true;
    selectedTitikIkatNotifier.value = titikIkat;
    selectedTitikIkatClusterNotifier.value = cluster;
    selectedLocationNotifier.value = Position(
      titikIkat.longitude!,
      titikIkat.latitude!,
    );
    Navigator.pushNamed(context, 'location_map_page');
  }

  Widget _image(TitikIkatModel titikIkat) => CachedNetworkImage(
    imageUrl: GDriveThumbnailService.toThumbnailUrl(titikIkat.urlFoto!),
    fit: BoxFit.cover,
    placeholder:
        (_, __) => const Center(
          child: SizedBox.square(
            dimension: 28,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
    errorWidget:
        (_, __, ___) =>
            const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
  );

  void _openPhoto(BuildContext context, TitikIkatModel titikIkat, String tag) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => _TitikIkatPhotoPreview(
              imageUrl: GDriveThumbnailService.toThumbnailUrl(
                titikIkat.urlFoto!,
              ),
              heroTag: tag,
            ),
      ),
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
                            'Titik referensi ${cluster.kodeCluster}',
                            style: TextStyle(color: foreground),
                          ),
                          childrenPadding: const EdgeInsets.fromLTRB(
                            16,
                            0,
                            16,
                            14,
                          ),
                          children: [
                            if (titikIkat.urlFoto?.trim().isNotEmpty ==
                                true) ...[
                              Builder(
                                builder: (context) {
                                  final tag =
                                      'anchor_photo_${titikIkat.id}_${titikIkat.urlFoto.hashCode}';
                                  return Align(
                                    alignment: Alignment.centerLeft,
                                    child: SizedBox.square(
                                      dimension: 120,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            onTap:
                                                () => _openPhoto(
                                                  context,
                                                  titikIkat,
                                                  tag,
                                                ),
                                            child: Hero(
                                              tag: tag,
                                              child: _image(titikIkat),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 10),
                            ],
                            Table(
                              columnWidths: const {
                                0: FlexColumnWidth(1.1),
                                1: FlexColumnWidth(1.9),
                              },
                              children: [
                                _row(
                                  'Lintang',
                                  titikIkat.latitude?.toStringAsFixed(6) ?? '-',
                                  foreground,
                                ),
                                _row(
                                  'Bujur',
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
                            if (titikIkat.latitude != null &&
                                titikIkat.longitude != null) ...[
                              const SizedBox(height: 10),
                              Align(
                                alignment: Alignment.centerRight,
                                child: OutlinedButton.icon(
                                  onPressed:
                                      () => _trackLocation(context, titikIkat),
                                  icon: Icon(
                                    Icons.my_location,
                                    color: foreground,
                                  ),
                                  label: Text(
                                    'Tracking Data',
                                    style: TextStyle(color: foreground),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                      color:
                                          isDark ? Colors.white54 : Colors.grey,
                                    ),
                                    foregroundColor: foreground,
                                  ),
                                ),
                              ),
                            ],
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

class _TitikIkatPhotoPreview extends StatelessWidget {
  const _TitikIkatPhotoPreview({required this.imageUrl, required this.heroTag});

  final String imageUrl;
  final String heroTag;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    body: SafeArea(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.pop(context),
        child: Center(
          child: InteractiveViewer(
            minScale: 1,
            maxScale: 5,
            child: Hero(
              tag: heroTag,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
                placeholder: (_, __) => const CircularProgressIndicator(),
                errorWidget:
                    (_, __, ___) => const Icon(
                      Icons.broken_image,
                      color: Colors.white70,
                      size: 48,
                    ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
