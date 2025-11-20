import 'package:azimutree/views/widgets/manage_data_widget/btm_button_manage_data_widget.dart';
import 'package:azimutree/views/widgets/manage_data_widget/dialog_add_cluster_widget.dart';
import 'package:flutter/material.dart';

class BottomsheetManageDataWidget extends StatefulWidget {
  const BottomsheetManageDataWidget({super.key});

  @override
  State<BottomsheetManageDataWidget> createState() =>
      _BottomsheetManageDataWidgetState();
}

class _BottomsheetManageDataWidgetState
    extends State<BottomsheetManageDataWidget> {
  late final DraggableScrollableController _draggableScrollableController;
  final double _maxChildSize = 0.9;
  final double _minChildSize = 0.1;

  @override
  void initState() {
    super.initState();
    _draggableScrollableController = DraggableScrollableController();
  }

  void _expandBottomSheet() {
    _draggableScrollableController.animateTo(
      _maxChildSize,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _draggableScrollableController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      controller: _draggableScrollableController,
      initialChildSize: 0.1,
      minChildSize: _minChildSize,
      maxChildSize: _maxChildSize,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Color.fromARGB(255, 205, 237, 211),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: ListView(
              controller: scrollController,
              children: [
                ListTile(
                  title: TextButton(
                    onPressed: () {
                      _expandBottomSheet();
                    },
                    child: Text(
                      'Menu Kelola Data',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                Text(
                  'Pilih salah satu opsi di bawah untuk mengelola data Anda. Impor data untuk menambahkan data dari file eksternal (sheet), ekspor data untuk menyimpan salinan data Anda, atau unduh template untuk format data (sheet) yang benar.',
                  textAlign: TextAlign.justify,
                ),
                SizedBox(height: 20),
                Wrap(
                  spacing: 20,
                  runSpacing: 20,
                  alignment: WrapAlignment.spaceEvenly,
                  children: [
                    BtmButtonManageDataWidget(
                      label: "Ekspor Data",
                      icon: Icons.file_upload,
                      onPressed: () {
                        //? TODO: Handle export data action
                      },
                    ),
                    BtmButtonManageDataWidget(
                      label: "Impor Data",
                      icon: Icons.file_download,
                      onPressed: () {
                        //? TODO: Handle import data action
                      },
                    ),
                    BtmButtonManageDataWidget(
                      label: "Unduh Template",
                      icon: Icons.description,
                      onPressed: () {
                        //? TODO: Handle download template action
                      },
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Text("Atau tembah data baru secara manual:"),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.spaceEvenly,
                  children: [
                    BtmButtonManageDataWidget(
                      label: "Klaster",
                      minSize: Size(100, 40),
                      maxSize: Size(150, 70),
                      onPressed: () {
                        showDialog(
                          barrierDismissible: false,
                          context: context,
                          builder: (context) => DialogAddClusterWidget(),
                        );
                      },
                    ),
                    BtmButtonManageDataWidget(
                      label: "Plot",
                      minSize: Size(100, 40),
                      maxSize: Size(150, 70),
                      onPressed: () {
                        //? TODO: Handle add new plot action
                      },
                    ),
                    BtmButtonManageDataWidget(
                      label: "Pohon",
                      minSize: Size(100, 40),
                      maxSize: Size(150, 70),
                      onPressed: () {
                        //? TODO: Handle add new tree action
                      },
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Text("Debug options:"),
                ElevatedButton(
                  onPressed: () {
                    //? TODO: Fill random data
                  },
                  child: Text("Generate Data Random"),
                ),
                ElevatedButton(
                  onPressed: () {
                    //? TODO: Fill random data
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 131, 30, 23),
                    foregroundColor: Colors.white,
                  ),
                  child: Text("Hapus Semua Data"),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
