import 'package:azimutree/data/notifiers.dart';
import 'package:flutter/material.dart';

class LocationMapPage extends StatelessWidget {
  const LocationMapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Location Map Page"),
          ValueListenableBuilder(
            valueListenable: selectedPageNotifier,
            builder: (context, selectedPage, child) {
              return ElevatedButton(
                onPressed: () {
                  selectedPageNotifier.value = "home";
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Color(0xFF1F4226),
                  minimumSize: Size(50, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [Icon(Icons.skip_previous), Text("Back")],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
