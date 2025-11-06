import 'package:flutter/material.dart';

class BottomsheetManageDataWidget extends StatelessWidget {
  const BottomsheetManageDataWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.1,
      minChildSize: 0.1,
      maxChildSize: 1,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Color.fromARGB(255, 205, 237, 211),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
            ],
          ),
        );
      },
    );
  }
}
