import 'package:dfuapp/main.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/user_sql_helper.dart';
import 'case_select_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // All journals
  List<Map<String, dynamic>> _journals = [];
  final keyIsFirstLoaded = 'is_first_loaded';
  final welcomeDialogue = '''
This app is currently a work-in-progress tool to help Forensic Analysts and Law Enforcement to help keep track of their actions taken. 
Whilst this app may be used to create evidence to be used in a court of law, this is not a replacement for a proper case file.
Do not use this app in an evidential circumstance unless prior approval is given from your supervisors or SLT.

This app is currently undergoing a TestFlight - as such, please report any bugs you find through the TestFlight app or by email.
''';

  bool _isLoading = true;
  // This function is used to fetch all data from the database
  void _refreshJournals() async {
    final data = await SQLHelper.getItems();
    setState(() {
      _journals = data;
      _isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _refreshJournals(); // Loading the diary when the app starts
  }

  final TextEditingController _userController = TextEditingController();
  final TextEditingController _initialsController = TextEditingController();
  final TextEditingController _unitController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // This function will be triggered when the floating button is pressed
  // It will also be triggered when you want to update an item
  void _showForm(int? id) async {
    if (id != null) {
      // id == null -> create new item
      // id != null -> update an existing item
      final existingJournal = _journals.firstWhere((element) => element['id'] == id);
      _userController.text = existingJournal['user'];
      _initialsController.text = existingJournal['initials'];
      _unitController.text = existingJournal['unit'];
    } else {
      _userController.text = '';
      _initialsController.text = '';
      _unitController.text = '';
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
                    controller: _userController,
                    decoration: const InputDecoration(hintText: 'Name'),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  TextField(
                    controller: _initialsController,
                    decoration: const InputDecoration(hintText: 'Initials'),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  TextField(
                    controller: _unitController,
                    decoration: const InputDecoration(hintText: 'Unit'),
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

                      // Clear the text fields
                      _userController.text = '';
                      _initialsController.text = '';
                      _unitController.text = '';
                      _descriptionController.text = '';

                      // Close the bottom sheet
                      Navigator.of(context).pop();
                    },
                    child: Text(id == null ? 'Create New' : 'Update'),
                  )
                ],
              ),
            ));
  }

// Insert a new journal to the database
  Future<void> _addItem() async {
    await SQLHelper.createItem(_userController.text, _initialsController.text, _unitController.text);
    _refreshJournals();
  }

  // Update an existing journal
  Future<void> _updateItem(int id) async {
    await SQLHelper.updateItem(id, _userController.text, _initialsController.text, _unitController.text);
    _refreshJournals();
  }

  // Delete an item
  void _deleteItem(int id) async {
    await SQLHelper.deleteItem(id);
    rootScaffoldMessengerKey.currentState?.showSnackBar(const SnackBar(
      content: Text('Successfully deleted a user!'),
    ));
    _refreshJournals();
  }

  // First time open dialog to welcome the user
  showDialogIfFirstLoaded(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? isFirstLoaded = prefs.getBool(keyIsFirstLoaded);
    if (isFirstLoaded == null) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          // return object of type Dialog
          return AlertDialog(
            title: const Text("Welcome to FAPH - Forensic Acquisition Photograph Helper"),
            content: Text(welcomeDialogue),
            actions: <Widget>[
              // usually buttons at the bottom of the dialog
              ElevatedButton(
                child: const Text("Dismiss"),
                onPressed: () {
                  // Close the dialog
                  Navigator.of(context).pop();
                  prefs.setBool(keyIsFirstLoaded, false);
                },
              ),
            ],
          );
        },
      );
    }
  }

  // Widget builder for the inner UI
  @override
  Widget build(BuildContext context) {
    Future.delayed(Duration.zero, () => showDialogIfFirstLoaded(context));
    return Scaffold(
      appBar: AppBar(
        title: const Text('DFU Photo Overlay'),
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
                    title: Text(_journals[index]['user']),
                    subtitle: Text(_journals[index]['initials']),
                    trailing: SizedBox(
                      width: 170,
                      child: Row(
                        children: [
                          ElevatedButton(
                            child: const Text("Cases"),
                            onPressed: () {
                              /* Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) {
                                  return CasePage();
                                }),
                              ); */
                              Navigator.pushNamed(context, CasePage.routeName,
                                  arguments: ScreenArguments(
                                    _journals[index]['id'], //TODO Get user_id and pass to router
                                    _journals[index]['user'],
                                    _journals[index]['initials'],
                                  ));
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _showForm(_journals[index]['id']),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _showConf(context, "delete", _journals[index]['id']),
                          ),
                        ],
                      ),
                    )),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _showForm(null),
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
