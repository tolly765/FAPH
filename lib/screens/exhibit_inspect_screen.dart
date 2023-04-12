import 'dart:io';

import 'package:dfuapp/main.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../services/case_inspect_sql_helper.dart';
import '../services/exhibit_item_sql_helper.dart';
import '../services/fact_debug.dart';
import '../services/user_sql_helper.dart';

final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();
ExhibitViewPageArguments? args;

class ExhibitViewPage extends StatefulWidget {
  const ExhibitViewPage({Key? key}) : super(key: key);

  //Define routename
  static const routeName = '/case/items/extractArguments';

  @override
  _ExhibitViewPageState createState() => _ExhibitViewPageState();
}

// Define argument variables from route
class ExhibitViewPageArguments {
  final int exhibitID;

  ExhibitViewPageArguments(
    this.exhibitID,
  );
}

class _ExhibitViewPageState extends State<ExhibitViewPage> with RouteAware {
  // All journals
  List<Map<String, dynamic>> _journals = [];
  List<Map<String, dynamic>> _userJournals = [];

  bool _isLoading = true;

  // This function is used to fetch all data from the database
  void _refreshJournals() async {
    final data = await ExhibitItemSQLHelper.getItemsByExhibit((args != null) ? args!.exhibitID : 0);

    final userData = await SQLHelper.getItem(args!.exhibitID.toInt());

    setState(() {
      _journals = data;
      _userJournals = userData;
      _isLoading = false;
    });
  }

  Future<int?> _getItemCount() async {
    int? itemCount = await CaseViewSQLHelper.getItemCount();
    return itemCount;
  }

  // Set up initState
  @override
  void initState() {
    super.initState();
    // Gather arguments from route in preparation for SQLHelpers
    Future.delayed(Duration.zero, () {
      setState(() {
        args = ModalRoute.of(context)!.settings.arguments as ExhibitViewPageArguments;
      });
      _refreshJournals(); // Loading the diary when the app starts
    });
  }

  TextEditingController _caseNoController = new TextEditingController();
  TextEditingController _caseAsigneeController = new TextEditingController();

// //   // Update an existing journal
//   Future<void> _updateItem(int id) async {
//     await CaseViewSQLHelper.updateItem(id, '', '', _caseNoController.text, (args != null) ? args!.case_asignee : "",
//         (args != null) ? args!.user : _caseAsigneeController.text);
//     _refreshJournals();
//   }

  // Obtain reference to item for deletion
  Future<File> _localFile(int id) async {
    final path = await CaseViewSQLHelper.getItem(id);
    dprint('IMAGE PATH: ${path[0]['image_path']}');
    return File('${path[0]['image_path']}');
  }

  // Delete an item from the DB and the file store
  void _deleteItem(int id) async {
    dprint("ID: $id");
    final file = await _localFile(id);
    try {
      await file.delete();
    } on FileSystemException {
      rootScaffoldMessengerKey.currentState?.showSnackBar(const SnackBar(
        content: Text('Stale reference found and removed. Reloading page...'),
      ));
    }
    ;

    await CaseViewSQLHelper.deleteItem(id);
    rootScaffoldMessengerKey.currentState?.showSnackBar(const SnackBar(
      content: Text('Successfully deleted a case exhibit!'),
    ));
    _refreshJournals();
  }

  // Widget builder for the inner UI
  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as ExhibitViewPageArguments;

    return FutureBuilder(
      future: ExhibitItemSQLHelper.getItemsByExhibit(args.exhibitID),
      builder: (context, snapshot) {
        return Scaffold(
          appBar: AppBar(
            title: Text('Exhibit Reference: ${args.exhibitID}'),
          ),
          body: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisSpacing: 20, crossAxisCount: 2, mainAxisSpacing: 30),
                  itemCount: (snapshot.data as List<dynamic>).length,
                  itemBuilder: (BuildContext ctx, index) {
                    return itemContainer(snapshot, index);
                  },
                ),
        );
      },
    );
  }

  void _listofFiles() async {
    String directory = (await getApplicationDocumentsDirectory()).path;
    setState(() {
      List file = Directory(directory).listSync(); //use your folder name insted of resume.
      file.sort((a, b) => a.path.split('/').last.compareTo(b.path.split('/').last));
      eprint(file);
    });
  }

  // Item container to populate case information
  Widget itemContainer(snapshot, int index) {
    final args = ModalRoute.of(context)!.settings.arguments as ExhibitViewPageArguments;
    Map<String, dynamic> entry = (snapshot.data as List<dynamic>)[index];
    wprint("Exhibit itemCount: $index");
    wprint("fk_exhibit_id: ${args.exhibitID}");

    return Container(
        decoration:
            BoxDecoration(color: const Color.fromARGB(255, 255, 244, 205), borderRadius: BorderRadius.circular(30)),
        alignment: Alignment.center,
        // First child FutureBuilder - gather exhibit items
        child: FutureBuilder(
          future: getApplicationDocumentsDirectory(), // path_provider invocation
          builder: ((context, snapshot) {
            if (snapshot.hasData) {
              Directory appDirectory = snapshot.data as Directory; // Save appDirectory var from snapshot future
              String fullImagePath =
                  "${appDirectory.path}/${entry['image_path']}"; // Stitch together appDirectory and firstExhibit path
              wprint(entry['exhibit_item_id'].toString());
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Grab first exhibit item reference from exhibit and pass on to title card
                  Text(entry['exhibit_item_ref'].toString()),
                  Image.file(File(fullImagePath)), // Use stitched together path for image preview
                  const SizedBox(height: 10), // Spacer for bottom bar of widget
                  // Row(
                  //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  //   mainAxisSize: MainAxisSize.max,
                  //   children: [
                  //     // View button widget
                  //     ElevatedButton(
                  //       child: const Text("View"),
                  //       onPressed: () {
                  //         // Navigator.pushNamed(
                  //         //   context,
                  //         //   ExhibitViewPage.routeName,
                  //         //   arguments: ExhibitViewPageArguments(
                  //         //     //TODO Provide arguments such as case reference and exhibit reference
                  //         //     entry['fk_exhibit_id'],
                  //         //   ),
                  //         // ).then((_) => _refreshJournals());
                  //       },
                  //     ),
                  //     // Add to Exhibit button
                  //     ElevatedButton(
                  //       child: const Text("Add to exhibit"),
                  //       onPressed: () {},
                  //     ),
                  //     // Remove button
                  //     ElevatedButton(
                  //       child: const Text("Remove"),
                  //       onPressed: () {
                  //         // _showConf(context, "delete", _journals[index]['item_id']);
                  //       },
                  //     ),
                  //   ],
                  // )
                ],
              );
            } else {
              return const CircularProgressIndicator();
            }
          }),
        ));
  }
}

Future _getFilePath() async {
  // Application documents directory: /data/user/0/{package_name}/{app_name}
  final applicationDirectory = await getApplicationDocumentsDirectory();

  // Application temporary directory: /data/user/0/{package_name}/cache
  final tempDirectory = await getTemporaryDirectory();
  return applicationDirectory.path;
}
