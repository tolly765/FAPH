import 'dart:io';

import 'package:dfuapp/main.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../services/fact_debug.dart';
import '../services/user_sql_helper.dart';
import '../services/exhibit_sql_helper.dart';
import '../services/exhibit_item_sql_helper.dart';
import '../services/case_inspect_sql_helper.dart';
import 'exhibit_existing_item.dart';
import './new_exhibit_screen.dart';
import 'exhibit_inspect_screen.dart';

final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();
CaseViewScreenArguments? args;

class CaseViewPage extends StatefulWidget {
  const CaseViewPage({Key? key}) : super(key: key);

  //Define routename
  static const routeName = '/case/items/viewItem/extractArguments';

  @override
  
   createState() => _CaseViewPageState();
}

// Define argument variables from route
class CaseViewScreenArguments {
  final int id;
  final String case_id;
  final String case_asignee;
  final String case_reference;
  final String user;
  final String initials;

  CaseViewScreenArguments(
    this.id,
    this.user,
    this.case_id,
    this.case_asignee,
    this.case_reference,
    this.initials,
  );
}

class _CaseViewPageState extends State<CaseViewPage> with RouteAware {
  // All journals
  List<Map<String, dynamic>> _journals = [];
  List<Map<String, dynamic>> _userJournals = [];

  bool _isLoading = true;

  // This function is used to fetch all data from the database
  void _refreshJournals() async {
    final data = await CaseViewSQLHelper.getItemsByCase((args != null) ? args!.case_id : '');
    dprint('User: ${args!.id.toString()}');

    final userData = await SQLHelper.getItem(args!.id.toInt());
    //(args!.id);

    setState(() {
      _journals = data;
      _userJournals = userData;
      _isLoading = false;
    });
  }

  // Set up initState
  @override
  void initState() {
    super.initState();
    // Gather arguments from route in preparation for SQLHelpers
    Future.delayed(Duration.zero, () {
      setState(() {
        args = ModalRoute.of(context)!.settings.arguments as CaseViewScreenArguments;
      });
      _refreshJournals(); // Loading the diary when the app starts
    });
  }

  TextEditingController _caseNoController = new TextEditingController();
  TextEditingController _caseAsigneeController = new TextEditingController();

  // This function will be triggered when the floating button is pressed
  // It will also be triggered when you want to update an item
  void _showForm(int? id) async {
    print(id);
    if (id != null) {
      // id == null -> create new item
      // id != null -> update an existing item
      final existingJournal = _journals.firstWhere((element) => element['case_id'] == id);
      _caseNoController.text = existingJournal['case_number'];
    } else {
      _caseNoController.text = '';
    }

    // Pop up box for entering information to the DB
    showModalBottomSheet(
        isScrollControlled: true,
        context: context,
        elevation: 5,
        builder: (_) => Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _caseNoController,
                    decoration: const InputDecoration(hintText: 'Case Reference'),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      // Save new journal

                      if (id != null) {
                        await _updateItem(id);
                      }

                      // Clear the text fields
                      _caseNoController.text = '';

                      // Close the bottom sheet
                      Navigator.of(context).pop();
                    },
                    child: Text(id == null ? 'Create New' : 'Update'),
                  )
                ],
              ),
            ));
  }

//   // Update an existing journal
  Future<void> _updateItem(int id) async {
    await CaseViewSQLHelper.updateItem(id, '', '', _caseNoController.text, (args != null) ? args!.case_asignee : "",
        (args != null) ? args!.user : _caseAsigneeController.text);
    _refreshJournals();
  }

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

    await CaseViewSQLHelper.deleteItem(id);
    rootScaffoldMessengerKey.currentState?.showSnackBar(const SnackBar(
      content: Text('Successfully deleted a case exhibit!'),
    ));
    _refreshJournals();
  }

  Future<List<Map<String, dynamic>>> _getFirstExhibitItem(exhibitID) async {
    List<Map<String, dynamic>> exhibitItemData = await ExhibitItemSQLHelper.getFirstExhibitItem(exhibitID);
    return exhibitItemData;
  }

  // Widget builder for the inner UI
  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as CaseViewScreenArguments;
    return FutureBuilder(
      future: ExhibitSQLHelper.getItemCount(args.case_id),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          int currentItemCount = snapshot.data as int;
          dprint("Current itemCount: $currentItemCount");
          return FutureBuilder(
            future: ExhibitItemSQLHelper.getItemByCase(args.case_id),
            builder: (context, snapshot) {
              // eprint("Entry Snapshot Data: ${snapshot.data}");
              return Scaffold(
                appBar: AppBar(
                  title: Text('Case Reference: ${args.case_reference}'),
                ),
                body: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(),
                      )
                    : GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisSpacing: 20, crossAxisCount: 2, mainAxisSpacing: 30),
                        // itemCount: (snapshot.data as List<dynamic>).length,
                        itemCount: currentItemCount,
                        itemBuilder: (BuildContext ctx, index) {
                          return itemContainer(snapshot, index);
                        }),
                floatingActionButton: FloatingActionButton(
                  child: const Icon(Icons.add),
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      ExhibitInfoPage.routeName,
                      arguments: ExhibitInfoPageArguments(
                        //TODO Provide arguments such as case reference and exhibit reference
                        args.id,
                        args.case_id,
                        args.case_reference,
                        args.user,
                        _userJournals[0]['initials'],
                        true, // is new item?
                      ),
                    ).then((_) => _refreshJournals());
                  },
                ),
              );
            },
          );
        } else {
          return const CircularProgressIndicator();
        }
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
    final args = ModalRoute.of(context)!.settings.arguments as CaseViewScreenArguments;
    Map<String, dynamic> entry = (snapshot.data as List<dynamic>)[index];

    return Container(
      decoration:
          BoxDecoration(color: const Color.fromARGB(255, 255, 244, 205), borderRadius: BorderRadius.circular(30)),
      alignment: Alignment.center,
      // First child FutureBuilder - gather exhibit items
      child: FutureBuilder(
        // future: _getFilePath(),
        // future: _getFirstExhibitItem(entry['fk_exhibit_id']),
        future: ExhibitSQLHelper.getUniqueExhibitItems(args.case_id),

        builder: (context, snapshot) {
          if (snapshot.hasData) {
            // Save snapshot data for future use and prepare for next FutureBuilder
            // Save firstExhibit value for use in child Future imagepaths
            // List<Map<String, dynamic>> firstExhibit = snapshot.data as List<Map<String, dynamic>>;
            List<Map<String, dynamic>> uniqueExhibitItems = snapshot.data as List<Map<String, dynamic>>;
            // wprint(uniqueExhibitItems);
            // dprint("Index: $index | Snapshot: ${firstExhibit[0]}");

            // Second child FutureBuilder - provide current application directory
            return FutureBuilder(
              future: getApplicationDocumentsDirectory(), // path_provider invocation
              builder: ((context, snapshot) {
                if (snapshot.hasData) {
                  Directory appDirectory = snapshot.data as Directory; // Save appDirectory var from snapshot future
                  var exhibit_item_id = entry['exhibit_item_id'];
                  String fullImagePath =
                      "${appDirectory.path}/${uniqueExhibitItems[index]['image_path']}"; // Stitch together appDirectory and firstExhibit path
                  eprint(fullImagePath);
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Grab first exhibit item reference from exhibit and pass on to title card
                      Text(uniqueExhibitItems[index]['exhibit_item_ref'].toString()),
                      Image.file(File(fullImagePath)), // Use stitched together path for image preview
                      const SizedBox(height: 10), // Spacer for bottom bar of widget
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          // View button widget
                          ElevatedButton(
                            child: const Text("View"),
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                ExhibitViewPage.routeName,
                                arguments: ExhibitViewPageArguments(
                                  //TODO Provide arguments such as case reference and exhibit reference
                                  uniqueExhibitItems[index]['fk_exhibit_id'],
                                ),
                              ).then((_) => _refreshJournals());
                            },
                          ),
                          // Add to Exhibit button
                          ElevatedButton(
                            child: const Text("Add to exhibit"),
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                ExistingItemPage.routeName,
                                arguments: ExistingItemPageArguments(
                                  //TODO Provide arguments such as case reference and exhibit reference
                                  uniqueExhibitItems[index]['exhibit_item_ref'].toString(),
                                  // entry['fk_exhibit_id'],
                                  uniqueExhibitItems[index]['fk_exhibit_id'],
                                  '', // itemtype //TODO Get ItemType for DB completion
                                  args.case_id,
                                  _userJournals[0]['initials'],
                                  args.case_reference,
                                  args.user,
                                ),
                              ).then((_) => _refreshJournals());
                            },
                          ),
                          // Remove button
                          ElevatedButton(
                            child: const Text("Remove"),
                            onPressed: () {
                              _showConf(context, "delete", _journals[index]['item_id']);
                            },
                          ),
                        ],
                      )
                    ],
                  );
                } else {
                  return const CircularProgressIndicator();
                }
              }),
            );
          } else {
            return const CircularProgressIndicator();
          }
        },
      ),
    );
  }

  Future<void> _showConf(BuildContext context, String action, int journalID) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('CAUTION'),
          content: SingleChildScrollView(
            child: ListBody(
              children: const <Widget>[
                Text('This action will be irreversible!'),
                Text('Are you sure you want to continue?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Confirm'),
              onPressed: () {
                if (action == "delete") {
                  _deleteItem(journalID);
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
