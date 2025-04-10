import 'package:flutter/material.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  String currentTheme = "light";

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Color(0xFF1F4226),
            minimumSize: Size(150, 100),
            maximumSize: Size(200, 150),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF1F4226),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        scaffoldBackgroundColor: Colors.white,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text("Home"),
          actions: [
            Text("Light Theme"),
            IconButton(
              onPressed: () {
                setState(() {
                  currentTheme = currentTheme == "light" ? "dark" : "light";
                });
              },
              icon: Icon(Icons.light_mode),
            ),
          ],
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(color: Color(0xFF1F4226)),
                child: Text(
                  'Menu',
                  style: TextStyle(color: Colors.white, fontSize: 24),
                ),
              ),
              ListTile(
                leading: Icon(Icons.photo_camera),
                title: Text('Scan Kode Label'),
                onTap: () {},
              ),
              ListTile(
                leading: Icon(Icons.storage),
                title: Text('Kelola Data Sampel'),
                onTap: () {},
              ),
              ListTile(
                leading: Icon(Icons.map),
                title: Text('Peta Lokasi Cluster Plot'),
                onTap: () {},
              ),
              ListTile(
                leading: Icon(Icons.book),
                title: Text('Panduan Aplikasi'),
                onTap: () {},
              ),
              Divider(),
              ListTile(
                leading: Icon(Icons.settings),
                title: Text('Settings'),
                onTap: () {},
              ),
              ListTile(
                leading: Icon(Icons.info),
                title: Text('About'),
                onTap: () {},
              ),
              Divider(),
            ],
          ),
        ),
        body: Stack(
          children: [
            Image(
              image: AssetImage("assets/images/$currentTheme-bg-notitle.png"),
              fit: BoxFit.cover,
              height: double.infinity,
              width: double.infinity,
            ),
            Center(
              heightFactor: 3,
              child: Image(
                image: AssetImage("assets/images/$currentTheme-title.png"),
                fit: BoxFit.cover,
                width: 250,
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: 220),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      ElevatedButton(
                        onPressed: () {},
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.photo_camera, size: 30),
                            Text(
                              "Scan\nKode Label",
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {},
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.storage, size: 30),
                            Text(
                              "Kelola\nData Sampel",
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      ElevatedButton(
                        onPressed: () {},
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.map, size: 30),
                            Text(
                              "Peta Lokasi\nCluster Plot",
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {},
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.book, size: 30),
                            Text(
                              "Panduan\nAplikasi",
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
