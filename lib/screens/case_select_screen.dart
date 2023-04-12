import 'dart:io';

import 'package:dfuapp/main.dart';
import 'package:dfuapp/services/fact_debug.dart';
import '../services/case_sql_helper.dart';
import 'case_inspect_screen.dart';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive_io.dart';
import 'package:share_plus/share_plus.dart';

final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();
ScreenArguments? args;

class CasePage extends StatefulWidget {
  const CasePage({Key? key}) : super(key: key);

  //Define routename
  static const routeName = '/case/extractArguments';

  @override
  _CasePageState createState() => _CasePageState();
}

// Define argument variables from route
class ScreenArguments {
  final int id;
  final String user;
  final String initials;

  ScreenArguments(this.id, this.user, this.initials);
}

class _CasePageState extends State<CasePage> with RouteAware {
  // All journals
  List<Map<String, dynamic>> _journals = [];
  TextEditingController _caseNoController = new TextEditingController();
  TextEditingController _caseAsigneeController = new TextEditingController();
  bool _isLoading = true;
  late String _appPath;

  // This function is used to fetch all data from the database
  void _refreshJournals() async {
    final data = await CaseSQLHelper.getItem((args != null) ? args!.user : '');
    String appPath = (await getApplicationDocumentsDirectory()).path;
    setState(() {
      _journals = data;
      _isLoading = false;
      _appPath = appPath;
    });
  }

  // Set up initState
  @override
  void initState() {
    super.initState();
    // Gather arguments from route in preparation for SQLHelpers
    Future.delayed(Duration.zero, () {
      setState(() {
        args = ModalRoute.of(context)!.settings.arguments as ScreenArguments;
      });
      _refreshJournals(); // Loading the diary when the app starts
    });
  }

  // This function will be triggered when the floating button is pressed
  // It will also be triggered when you want to update an item
  void _showForm(int? id) async {
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
                      if (id == null) {
                        await _addItem();
                      }

                      if (id != null) {
                        await _updateItem(id);
                      }

                      // new Directory("$_appPath/${_caseNoController.text}").createSync(recursive: true);
                      Directory("$_appPath/${args?.user}/${_caseNoController.text}")
                          .create(recursive: true)
                          .then((_) => {
                                // Close the bottom sheet
                                dprint("Folder created"),
                                Navigator.of(context).pop(),
                              });
                      // Clear the text fields
                      _caseNoController.text = '';
                    },
                    child: Text(id == null ? 'Create New' : 'Update'),
                  )
                ],
              ),
            ));
  }

// Insert a new journal to the database
  Future<void> _addItem() async {
    await CaseSQLHelper.createItem(_caseNoController.text, (args != null) ? args!.user : _caseAsigneeController.text);
    _refreshJournals();
  }

  // Update an existing journal
  Future<void> _updateItem(int id) async {
    await CaseSQLHelper.updateItem(
        id, _caseNoController.text, (args != null) ? args!.user : _caseAsigneeController.text);
    _refreshJournals();
  }

  // Delete an item
  void _deleteItem(int id) async {
    await CaseSQLHelper.deleteItem(id);
    rootScaffoldMessengerKey.currentState?.showSnackBar(const SnackBar(
      content: Text('Successfully deleted a case!'),
    ));
    _refreshJournals();
  }

  void createZip(BuildContext context, user, folder) {
    var encoder = ZipFileEncoder();
    // Manually create a zip of a directory and individual files.
    try {
      encoder.create('$_appPath/$user/output.zip');
      encoder.addDirectory(Directory("$_appPath/$user/$folder"));
      encoder.close();
    } catch (e) {
      eprint(e);
      rootScaffoldMessengerKey.currentState?.showSnackBar(SnackBar(
        content: Text('ERROR: $e'),
      ));
      encoder.close();
    }
    dprint("Finished zipping");
  }

  void _onShare(BuildContext context, String user) async {
    XFile outputZip = XFile('$_appPath/$user/output.zip');
    final box = context.findRenderObject() as RenderBox?;
    await Share.shareXFiles([outputZip],
        subject: "FAPH Output.zip", sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size);
  }

  // Widget builder for the inner UI
  @override
  Widget build(BuildContext context) {
    final args_ = ModalRoute.of(context)!.settings.arguments as ScreenArguments;
    return Scaffold(
      appBar: AppBar(
        title: Text('DFU Cases assigned to ${args_.user}'),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : ListView.builder(
              itemCount: _journals.length,
              itemBuilder: (context, index) => Card(
                color: Colors.orange[200],
                margin: const EdgeInsets.all(15),
                child: ListTile(
                  title: Text(_journals[index]['case_number']),
                  subtitle: Text(_journals[index]['case_asignee']),
                  trailing: SizedBox(
                    width: 213,
                    child: Row(
                      children: [
                        ElevatedButton(
                          child: const Text("Open"),
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              CaseViewPage.routeName,
                              arguments: CaseViewScreenArguments(
                                // _journals[index]['user_id'], //TODO Get user_id and pass to router
                                args_.id,
                                args_.user,
                                _journals[index]['case_id'].toString(),
                                _journals[index]['case_asignee'],
                                _journals[index]['case_number'],
                                args_.initials,
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.share),
                          onPressed: () {
                            exportPrompt(context, _journals[index]['case_number']);
                          }, // TODO: Get export prompt from file_exporter.dart
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _showForm(_journals[index]['case_id']),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _deleteItem(_journals[index]['case_id']),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _showForm(null),
      ),
    );
  }

  Future<void> exportPrompt(BuildContext context, String folderName) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Export Case'),
          content: SingleChildScrollView(
            child: ListBody(
              children: const <Widget>[
                Text('You have chosen to export your current case.'),
                Text('How would you like to proceed?'),
              ],
            ),
          ),
          actions: <Widget>[
            Builder(
              builder: (BuildContext context) {
                return TextButton(
                  child: const Text('Share Via...'),
                  onPressed: () {
                    // Navigator.of(context).pop();
                    createZip(context, args!.user, folderName);
                    // onShare needs to be called after createZip, otherwise the Share Via menu will not appear
                    _onShare(context, args!.user);
                    Navigator.pop(context);
                  },
                );
              },
            ),
            TextButton(
              child: const Text('Send to Web Server'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
