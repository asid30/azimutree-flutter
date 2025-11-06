import 'package:azimutree/views/widgets/btm_button_manage_data_widget.dart';
import 'package:flutter/material.dart';

class BottomsheetManageDataWidget extends StatelessWidget {
  const BottomsheetManageDataWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.1,
      minChildSize: 0.1,
      maxChildSize: 0.75,
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
                  title: Text(
                    'Menu Kelola Data',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold),
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
                        //? TODO: Handle import data action
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
                        //? TODO: Handle import data action
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
