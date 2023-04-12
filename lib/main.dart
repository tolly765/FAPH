// main.dart
import 'package:dfuapp/screens/exhibit_existing_item.dart';
import 'package:dfuapp/screens/new_exhibit_screen.dart';
import 'package:flutter/material.dart';

import 'screens/user_screen.dart';
import 'screens/case_select_screen.dart';
import 'screens/case_inspect_screen.dart';
import 'screens/exhibit_inspect_screen.dart';

Future<void> main() async {
  runApp(const MyApp());
}

// Define scaffold key for snackbar context
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        routes: {
          CasePage.routeName: (context) => const CasePage(),
          CaseViewPage.routeName: (context) => const CaseViewPage(),
          ExhibitInfoPage.routeName: (context) => const ExhibitInfoPage(),
          ExistingItemPage.routeName: (context) => const ExistingItemPage(),
          ExhibitViewPage.routeName: (context) => const ExhibitViewPage(),
        },

        // Scaffold key for snackbar context
        scaffoldMessengerKey: rootScaffoldMessengerKey,

        // Remove the debug b8anner
        debugShowCheckedModeBanner: false,
        title: 'FAPH - DFU Exhibit Overlayer',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const HomePage());
    // home: const CameraScreenPage());
  }
}
