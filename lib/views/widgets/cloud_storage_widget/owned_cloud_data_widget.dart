import 'package:azimutree/data/notifiers/notifiers.dart';
import 'package:azimutree/services/cloud_owned_data_service.dart';
import 'package:azimutree/views/widgets/alert_dialog_widget/alert_confirmation_widget.dart';
import 'package:azimutree/views/widgets/alert_dialog_widget/app_alert_service.dart';
import 'package:azimutree/views/widgets/alert_dialog_widget/app_form_dialog.dart';
import 'package:azimutree/views/widgets/alert_dialog_widget/rename_downloaded_cluster_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OwnedCloudDataWidget extends StatefulWidget {
  const OwnedCloudDataWidget({
    super.key,
    required this.user,
    required this.ownerName,
  });

  final User user;
  final String ownerName;

  @override
  State<OwnedCloudDataWidget> createState() => _OwnedCloudDataWidgetState();
}

class _OwnedCloudDataWidgetState extends State<OwnedCloudDataWidget> {
  final CloudOwnedDataService _service = CloudOwnedDataService();
  final Set<String> _expandedLocationIds = <String>{};
  bool _isProcessing = false;

  String _date(DateTime? value) =>
      value == null ? '-' : DateFormat('dd-MM-yyyy').format(value);

  Future<void> _createLocation() async {
    final result =
        await showDialog<({String name, DateTime date, bool isPublic})>(
          context: context,
          builder: (context) => const _CreateLocationDialog(),
        );
    if (result == null || !mounted) return;
    setState(() => _isProcessing = true);
    try {
      await _service.createLocation(
        ownerId: widget.user.uid,
        ownerName: widget.ownerName,
        name: result.name,
        researchDate: result.date,
        isPublic: result.isPublic,
      );
    } on StateError catch (error) {
      if (mounted) {
        await showAppWarning(context, error.message);
      }
    } on FirebaseException catch (error) {
      if (mounted) {
        await showAppError(
          context,
          error.code == 'permission-denied'
              ? 'Izin membuat lokasi ditolak. Keluar lalu masuk kembali ke akun.'
              : 'Lokasi gagal dibuat: ${error.message ?? error.code}',
        );
      }
    } catch (_) {
      if (mounted) {
        await showAppError(context, 'Lokasi penelitian gagal dibuat.');
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _deleteLocation(CloudOwnedResearchLocation location) async {
    if (location.clusterCount > 0) {
      await showAppWarning(
        context,
        'Hapus seluruh klaster di dalam folder terlebih dahulu.',
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertConfirmationWidget(
            title: 'Hapus Lokasi Penelitian?',
            message: 'Folder “${location.name}” akan dihapus permanen.',
          ),
    );
    if (confirmed != true) return;
    try {
      await _service.deleteEmptyLocation(location.id);
    } catch (_) {
      if (mounted) {
        await showAppError(context, 'Lokasi penelitian gagal dihapus.');
      }
    }
  }

  Future<void> _uploadClusters(CloudOwnedResearchLocation location) async {
    final snapshots = await _service.loadLocalSnapshots();
    if (!mounted) return;
    if (snapshots.isEmpty) {
      await showAppWarning(
        context,
        'Belum ada klaster pada penyimpanan lokal.',
      );
      return;
    }
    final selected = await showDialog<List<LocalClusterSnapshot>>(
      context: context,
      builder: (context) => _SelectClustersDialog(snapshots: snapshots),
    );
    if (selected == null || selected.isEmpty || !mounted) return;

    final overwritten =
        selected
            .map((item) => item.cluster.kodeCluster)
            .where(location.clusterCodes.contains)
            .toList();
    if (overwritten.isNotEmpty) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder:
            (_) => AlertConfirmationWidget(
              title: 'Timpa Data?',
              message:
                  'Klaster ${overwritten.join(', ')} sudah ada di folder ini. '
                  'Data lama akan diganti dengan data lokal terbaru.',
              confirmText: 'Lanjutkan',
            ),
      );
      if (confirmed != true || !mounted) return;
    }

    setState(() => _isProcessing = true);
    try {
      await _service.uploadSnapshots(
        locationId: location.id,
        snapshots: selected,
      );
      if (mounted) {
        await showAppSuccess(
          context,
          '${selected.length} data klaster berhasil diunggah.',
        );
      }
    } on FirebaseException catch (error) {
      if (mounted) {
        await showAppError(
          context,
          'Unggah gagal (${error.code}): ${error.message ?? 'kesalahan Firebase'}',
        );
      }
    } catch (_) {
      if (mounted) {
        await showAppError(
          context,
          'Data klaster gagal diunggah. Periksa koneksi.',
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _deleteCluster(
    CloudOwnedResearchLocation location,
    CloudOwnedCluster cluster,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertConfirmationWidget(
            title: 'Hapus Data Klaster?',
            message:
                'Data ${cluster.code} akan dihapus dari “${location.name}”. '
                'Data lokal tidak ikut terhapus.',
          ),
    );
    if (confirmed != true) return;
    try {
      await _service.deleteCluster(locationId: location.id, cluster: cluster);
    } catch (_) {
      if (mounted) {
        await showAppError(context, 'Data klaster gagal dihapus.');
      }
    }
  }

  Future<void> _downloadCluster(
    CloudOwnedResearchLocation location,
    CloudOwnedCluster cluster,
  ) async {
    var localCode = cluster.code;
    if (await _service.localCodeExists(localCode)) {
      if (!mounted) return;
      final replacement = await showDialog<String>(
        context: context,
        builder:
            (_) => RenameDownloadedClusterDialog(
              initialCode: '${cluster.code} SALINAN',
            ),
      );
      if (replacement == null) return;
      localCode = replacement;
      if (await _service.localCodeExists(localCode)) {
        if (mounted) {
          await showAppWarning(
            context,
            'Kode klaster tersebut sudah digunakan.',
          );
        }
        return;
      }
    }
    setState(() => _isProcessing = true);
    try {
      await _service.downloadCluster(
        locationId: location.id,
        clusterId: cluster.id,
        localCode: localCode,
      );
      localDataRevisionNotifier.value++;
      if (mounted) {
        await showAppSuccess(context, 'Klaster $localCode berhasil diunduh.');
      }
    } catch (_) {
      if (mounted) {
        await showAppError(context, 'Klaster gagal diunduh.');
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isLightModeNotifier,
      builder: (context, isLight, _) {
        final foreground = isLight ? Colors.black87 : Colors.white;
        final cardColor =
            isLight
                ? const Color.fromARGB(240, 180, 216, 187)
                : const Color.fromARGB(255, 32, 72, 43);
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.cloud_upload, size: 44, color: foreground),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kelola Data Sendiri',
                          style: TextStyle(
                            color: foreground,
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Buat lokasi penelitian untuk menampung data klaster.',
                          style: TextStyle(
                            color: foreground.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: _isProcessing ? null : _createLocation,
                icon: const Icon(Icons.create_new_folder),
                label: const Text('Buat Lokasi Penelitian'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: const Color(0xFF1F4226),
                ),
              ),
              if (_isProcessing) ...[
                const SizedBox(height: 8),
                const LinearProgressIndicator(),
              ],
              const SizedBox(height: 12),
              Expanded(
                child: StreamBuilder<List<CloudOwnedResearchLocation>>(
                  stream: _service.watchLocations(widget.user.uid),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return _message(
                        'Data milik Anda tidak dapat dimuat.',
                        cardColor,
                        foreground,
                      );
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final locations = snapshot.data!;
                    if (locations.isEmpty) {
                      return _message(
                        'Belum ada lokasi penelitian. Buat folder pertama Anda.',
                        cardColor,
                        foreground,
                      );
                    }
                    return ListView.builder(
                      itemCount: locations.length,
                      itemBuilder: (context, index) {
                        final location = locations[index];
                        return Card(
                          color: cardColor,
                          child: ExpansionTile(
                            key: PageStorageKey<String>(
                              'owned_location_${location.id}',
                            ),
                            initiallyExpanded: _expandedLocationIds.contains(
                              location.id,
                            ),
                            onExpansionChanged: (expanded) {
                              setState(() {
                                if (expanded) {
                                  _expandedLocationIds.add(location.id);
                                } else {
                                  _expandedLocationIds.remove(location.id);
                                }
                              });
                            },
                            shape: const Border(),
                            collapsedShape: const Border(),
                            leading: Icon(Icons.folder, color: foreground),
                            iconColor: foreground,
                            collapsedIconColor: foreground,
                            title: Text(
                              location.name,
                              style: TextStyle(
                                color: foreground,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              '${_date(location.researchDate)} · ${location.clusterCount} klaster\n${location.isPublic ? 'Publik' : 'Privat'}',
                              style: TextStyle(
                                color: foreground.withValues(alpha: 0.8),
                              ),
                            ),
                            childrenPadding: const EdgeInsets.fromLTRB(
                              16,
                              0,
                              16,
                              14,
                            ),
                            children: [
                              StreamBuilder<List<CloudOwnedCluster>>(
                                stream: _service.watchClusters(location.id),
                                builder: (context, clusterSnapshot) {
                                  final clusters =
                                      clusterSnapshot.data ?? const [];
                                  if (clusterSnapshot.connectionState ==
                                          ConnectionState.waiting &&
                                      clusters.isEmpty) {
                                    return const Padding(
                                      padding: EdgeInsets.all(8),
                                      child: CircularProgressIndicator(),
                                    );
                                  }
                                  if (clusters.isEmpty) {
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 10,
                                      ),
                                      child: Text(
                                        'Belum ada data klaster.',
                                        style: TextStyle(
                                          color: foreground.withValues(
                                            alpha: 0.75,
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                  return Column(
                                    children: [
                                      ...clusters.map(
                                        (cluster) => ListTile(
                                          contentPadding: EdgeInsets.zero,
                                          leading: Icon(
                                            Icons.data_object,
                                            color: foreground,
                                          ),
                                          title: Text(
                                            cluster.code,
                                            style: TextStyle(
                                              color: foreground,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          subtitle: Text(
                                            '${cluster.surveyorName} · ${_date(cluster.surveyDate)}',
                                            style: TextStyle(
                                              color: foreground.withValues(
                                                alpha: 0.75,
                                              ),
                                            ),
                                          ),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                onPressed:
                                                    _isProcessing
                                                        ? null
                                                        : () =>
                                                            _downloadCluster(
                                                              location,
                                                              cluster,
                                                            ),
                                                tooltip: 'Unduh ke aplikasi',
                                                color: foreground,
                                                icon: const Icon(
                                                  Icons.download_outlined,
                                                ),
                                              ),
                                              IconButton(
                                                onPressed:
                                                    _isProcessing
                                                        ? null
                                                        : () => _deleteCluster(
                                                          location,
                                                          cluster,
                                                        ),
                                                tooltip: 'Hapus data',
                                                color:
                                                    isLight
                                                        ? const Color.fromARGB(
                                                          255,
                                                          98,
                                                          32,
                                                          32,
                                                        )
                                                        : const Color.fromARGB(
                                                          255,
                                                          215,
                                                          83,
                                                          83,
                                                        ),
                                                icon: const Icon(Icons.delete),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                    ],
                                  );
                                },
                              ),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed:
                                      _isProcessing
                                          ? null
                                          : () => _uploadClusters(location),
                                  icon: const Icon(Icons.cloud_upload),
                                  label: const Text('Unggah Klaster'),
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    backgroundColor:
                                        isLight
                                            ? const Color(0xFF1F4226)
                                            : const Color(0xFF102C18),
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () async {
                                        try {
                                          await _service.updateVisibility(
                                            locationId: location.id,
                                            isPublic: !location.isPublic,
                                          );
                                        } catch (_) {
                                          if (context.mounted) {
                                            await showAppError(
                                              context,
                                              'Status publik gagal diubah.',
                                            );
                                          }
                                        }
                                      },
                                      icon: Icon(
                                        location.isPublic
                                            ? Icons.lock_outline
                                            : Icons.public,
                                      ),
                                      label: Text(
                                        location.isPublic
                                            ? 'Jadikan privat'
                                            : 'Jadikan publik',
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        backgroundColor:
                                            isLight
                                                ? const Color(0xFF1F4226)
                                                : const Color(0xFF102C18),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => _deleteLocation(location),
                                    tooltip: 'Hapus folder',
                                    color:
                                        isLight
                                            ? const Color.fromARGB(
                                              255,
                                              98,
                                              32,
                                              32,
                                            )
                                            : const Color.fromARGB(
                                              255,
                                              215,
                                              83,
                                              83,
                                            ),
                                    icon: const Icon(Icons.delete),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _message(String text, Color cardColor, Color foreground) => Align(
    alignment: Alignment.topCenter,
    child: Card(
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(color: foreground),
        ),
      ),
    ),
  );
}

class _SelectClustersDialog extends StatefulWidget {
  const _SelectClustersDialog({required this.snapshots});

  final List<LocalClusterSnapshot> snapshots;

  @override
  State<_SelectClustersDialog> createState() => _SelectClustersDialogState();
}

class _SelectClustersDialogState extends State<_SelectClustersDialog> {
  final Set<int> _selectedIds = {};

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isLightModeNotifier,
      builder: (context, isLight, _) {
        final isDark = !isLight;
        final foreground = isDark ? Colors.white : Colors.black87;
        final background =
            isDark ? const Color.fromARGB(255, 32, 72, 43) : Colors.white;
        return AppFormDialog(
          backgroundColor: background,
          title: Text('Pilih Klaster', style: TextStyle(color: foreground)),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: widget.snapshots.length,
              itemBuilder: (context, index) {
                final snapshot = widget.snapshots[index];
                final id = snapshot.cluster.id;
                if (id == null) return const SizedBox.shrink();
                return CheckboxListTile(
                  value: _selectedIds.contains(id),
                  contentPadding: EdgeInsets.zero,
                  activeColor: isDark ? Colors.white : const Color(0xFF1F4226),
                  checkColor: isDark ? const Color(0xFF1F4226) : Colors.white,
                  title: Text(
                    snapshot.cluster.kodeCluster,
                    style: TextStyle(
                      color: foreground,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    '${snapshot.plotCount} plot · ${snapshot.treeCount} pohon',
                    style: TextStyle(color: foreground.withValues(alpha: 0.75)),
                  ),
                  onChanged: (selected) {
                    setState(() {
                      if (selected == true) {
                        _selectedIds.add(id);
                      } else {
                        _selectedIds.remove(id);
                      }
                    });
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(foregroundColor: foreground),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed:
                  _selectedIds.isEmpty
                      ? null
                      : () => Navigator.pop(
                        context,
                        widget.snapshots
                            .where(
                              (snapshot) =>
                                  _selectedIds.contains(snapshot.cluster.id),
                            )
                            .toList(),
                      ),
              style: TextButton.styleFrom(
                foregroundColor: foreground,
                disabledForegroundColor: Colors.grey,
              ),
              child: const Text('Unggah'),
            ),
          ],
        );
      },
    );
  }
}

class _CreateLocationDialog extends StatefulWidget {
  const _CreateLocationDialog();

  @override
  State<_CreateLocationDialog> createState() => _CreateLocationDialogState();
}

class _CreateLocationDialogState extends State<_CreateLocationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  DateTime _date = DateTime.now();
  bool _isPublic = true;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_normalizeName);
  }

  void _normalizeName() {
    final buffer = StringBuffer();
    var capitalizeNext = true;
    for (final rune in _nameController.text.runes) {
      final character = String.fromCharCode(rune);
      if (character.trim().isEmpty) {
        buffer.write(character);
        capitalizeNext = true;
      } else {
        buffer.write(
          capitalizeNext ? character.toUpperCase() : character.toLowerCase(),
        );
        capitalizeNext = false;
      }
    }
    final normalized = buffer.toString();
    if (normalized == _nameController.text) return;
    _nameController.value = TextEditingValue(
      text: normalized,
      selection: TextSelection.collapsed(offset: normalized.length),
    );
  }

  @override
  void dispose() {
    _nameController.removeListener(_normalizeName);
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    FocusScope.of(context).unfocus();
    final selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        final isDark = !isLightModeNotifier.value;
        return Theme(
          data: isDark ? ThemeData.dark() : Theme.of(context),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (selected != null && mounted) setState(() => _date = selected);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isLightModeNotifier,
      builder: (context, isLight, _) {
        final isDark = !isLight;
        final foreground = isLight ? Colors.black87 : Colors.white;
        final labelColor = isDark ? Colors.white70 : Colors.black54;
        final background =
            isLight ? Colors.white : const Color.fromARGB(255, 32, 72, 43);
        return AppFormDialog(
          backgroundColor: background,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          title: Text(
            'Tambah Lokasi Penelitian',
            style: TextStyle(color: foreground),
          ),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _nameController,
                    maxLength: 100,
                    textCapitalization: TextCapitalization.words,
                    style: TextStyle(color: foreground),
                    cursorColor: foreground,
                    decoration: InputDecoration(
                      labelText: 'Nama lokasi penelitian',
                      hintText: 'Contoh: Taman Nasional Way Kambas',
                      labelStyle: TextStyle(color: labelColor),
                      hintStyle: TextStyle(color: labelColor),
                      counterStyle: TextStyle(color: labelColor),
                      border: const OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: isDark ? Colors.white54 : Colors.grey,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color:
                              isDark
                                  ? Colors.white
                                  : Theme.of(context).colorScheme.primary,
                          width: 2,
                        ),
                      ),
                    ),
                    validator: (value) {
                      final name = value?.trim() ?? '';
                      if (name.length < 3) return 'Nama minimal 3 karakter';
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    borderRadius: BorderRadius.circular(4),
                    onTap: _selectDate,
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Tanggal penelitian',
                        labelStyle: TextStyle(color: labelColor),
                        border: const OutlineInputBorder(),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: isDark ? Colors.white54 : Colors.grey,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              DateFormat('dd-MM-yyyy').format(_date),
                              style: TextStyle(color: foreground),
                            ),
                          ),
                          Icon(Icons.calendar_today, color: foreground),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Data publik',
                              style: TextStyle(color: foreground, fontSize: 16),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Dapat ditemukan dan diunduh pengguna lain',
                              style: TextStyle(color: labelColor, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _isPublic,
                        onChanged: (value) => setState(() => _isPublic = value),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(foregroundColor: foreground),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                if (!_formKey.currentState!.validate()) return;
                Navigator.pop(context, (
                  name: _nameController.text.trim(),
                  date: _date,
                  isPublic: _isPublic,
                ));
              },
              style: TextButton.styleFrom(foregroundColor: foreground),
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }
}
