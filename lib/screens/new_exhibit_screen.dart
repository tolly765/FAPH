// ignore_for_file: unused_element, unused_local_variable, avoid_print

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../main.dart';
import '../services/exhibit_item_sql_helper.dart';
import '../services/fact_debug.dart';
import '../services/image_overlayer.dart';
import '../services/exhibit_sql_helper.dart';

final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();
ExhibitInfoPageArguments? args;
final stopwatch = Stopwatch();

var imagePicker;

class ExhibitInfoPage extends StatefulWidget {
  const ExhibitInfoPage({Key? key}) : super(key: key);

  //Define routename
  static const routeName = '/case/items/itemConf/extractArguments';

  @override
  _ExhibitInfoPageState createState() => _ExhibitInfoPageState();
}

// Define argument variables from route
// Required: Case Reference/ID, itemID
class ExhibitInfoPageArguments {
  final int id;
  final String case_id;
  final String case_ref;
  final String user;
  final String initials;
  final bool isNew;

  ExhibitInfoPageArguments(
    this.id,
    this.case_id,
    this.case_ref,
    this.user,
    this.initials,
    this.isNew,
  );
}

class _ExhibitInfoPageState extends State<ExhibitInfoPage> with RouteAware {
  final _formKey = GlobalKey<FormBuilderState>();
  // All journals
  List<Map<String, dynamic>> _journals = [];

  bool _isLoading = false;
  bool _indicatorLoading = false;
  final bool addButtonEnable = false;
  String loadingText = "Loading...";

  // This function is used to fetch all data from the database
  void _refreshJournals() async {
    final data = await ExhibitSQLHelper.getItem((args != null) ? args!.case_id : '');

    print("User: ${args?.user}\nInitials: ${args?.initials}");
    setState(() {
      _journals = data;
      _isLoading = false;
    });
  }

  Future get _localPath async {
    // Application documents directory: /data/user/0/{package_name}/{app_name}
    final applicationDirectory = await getApplicationDocumentsDirectory();

    // Application temporary directory: /data/user/0/{package_name}/cache
    final tempDirectory = await getTemporaryDirectory();
    return applicationDirectory.parent.path;
  }

  // Set up initState
  @override
  void initState() {
    super.initState();
    // Gather arguments from route in preparation for SQLHelpers

    Future.delayed(Duration.zero, () {
      setState(() {
        args = ModalRoute.of(context)!.settings.arguments as ExhibitInfoPageArguments;
      });
      _refreshJournals(); // Loading the diary when the app starts
    });
    // Init Image Picker
    imagePicker = new ImagePicker();
  }

  final TextEditingController _caseNoController = TextEditingController();
  final TextEditingController _caseAsigneeController = TextEditingController();

  // This function will be triggered when the floating button is pressed
  // It will also be triggered when you want to update an item
  void _showForm(int? id) async {
    print(id);
    if (id != null) {
      final existingJournal = _journals.firstWhere((element) => element['case_id'] == id);
      _caseNoController.text = existingJournal['case_number'];
    } else {
      _caseNoController.text = '';
    }
  }

  Future<int?> _getItemCount() async {
    int? itemCount = await ExhibitSQLHelper.getItemCount(args!.case_id);
    return itemCount;
  }

  // Insert a new journal to the database
  Future<int> _addItem(itemtype, itemref, caseID) async {
    int exhibitID = await ExhibitSQLHelper.createItem(
      itemtype, // Case ref
      itemref, // Case asignee
      caseID, // Case ID
    );
    dprint('Item created on table "case_exhibits"');
    _refreshJournals();
    return exhibitID;
  }

  // Insert a new journal to the database
  Future<void> _contentsAddItem(itemref, imgpath, exhibitID, caseID) async {
    await ExhibitItemSQLHelper.createItem(
      itemref, // Case asignee
      imgpath, // Image path
      exhibitID, // exhibitID
      caseID, // Case ID
    );
    dprint('Item created on table "exhibit_contents": $itemref $imgpath $caseID');
    _refreshJournals();
  }

  // // Update an existing journal
  // Future<void> _updateItem(int id) async {
  //   await CaseViewSQLHelper.updateItem(
  //       id,
  //       _caseNoController.text,
  //       (args != null) ? args!.case_id : "",
  //       (args != null) ? args!.user : _caseAsigneeController.text);
  //   _refreshJournals();
  // }

  // Delete an item
  void _deleteItem(int id) async {
    await ExhibitSQLHelper.deleteItem(id);
    wprint('Successfuly deleted user id $id');
    rootScaffoldMessengerKey.currentState?.showSnackBar(const SnackBar(
      content: Text('Successfully deleted a user!'),
    ));
    _refreshJournals();
  }

  var _image;

  // Widget builder for the inner UI
  @override
  Widget build(BuildContext context) {
    /* final args_ =
        ModalRoute.of(context)!.settings.arguments as CaseViewScreenArguments; */
    final args = ModalRoute.of(context)!.settings.arguments as ExhibitInfoPageArguments;
    return Stack(children: [
      FutureBuilder(
        future: ExhibitSQLHelper.getItemCount(args.case_id),
        builder: (context, snapshot) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Add an exhibit'),
            ),
            body: _isLoading ? const Center(child: CircularProgressIndicator()) : exhibitForm(),
            // TODO Get Camera working on immediate call
          );
        },
      ),
      // If state is loading (e.g. picture is taken), overlay a loading indicator
      if (_indicatorLoading)
        const Opacity(
          opacity: 0.8,
          child: ModalBarrier(dismissible: false, color: Colors.black),
        ),
      if (_indicatorLoading)
        const Center(
          child: CircularProgressIndicator(),
        ),
      if (_indicatorLoading)
        Align(
          alignment: const Alignment(0, 0.2),
          child: Text(loadingText),
        ),
    ]);
  }

  Widget exhibitForm() {
    return FormBuilder(
      key: _formKey,
      autovalidateMode: AutovalidateMode.always,
      child: Column(
        children: <Widget>[
          FormBuilderTextField(
            name: 'item_ref',
            decoration: const InputDecoration(
              labelText: 'Item Reference',
            ),
            // valueTransformer: (text) => num.tryParse(text),
            validator: FormBuilderValidators.compose(
              [FormBuilderValidators.required()],
            ),
            keyboardType: TextInputType.text,
          ),
          FormBuilderChoiceChip(
            name: 'exhibit_type',
            decoration: const InputDecoration(
              labelText: 'Exhibit type',
            ),
            autovalidateMode: AutovalidateMode.always,
            options: const [
              FormBuilderChipOption(value: 'MOBILE', child: Text('Mobile Phone')),
              FormBuilderChipOption(value: 'HDD', child: Text('Hard Disk Drive')),
              FormBuilderChipOption(value: 'SSD', child: Text('SSD Drive')),
              FormBuilderChipOption(value: 'MEM', child: Text('Memory Card')),
              FormBuilderChipOption(value: 'USB', child: Text('USB Drive')),
              FormBuilderChipOption(value: 'CHIP', child: Text('Onboard Chip')),
              FormBuilderChipOption(value: 'DISC', child: Text('CD/DVD Disc')),
              FormBuilderChipOption(value: 'SIM', child: Text('SIM Card')),
            ],
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(
                errorText: "Please select an exhibit type.",
              )
            ]),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.saveAndValidate()) {
                    _formKey.currentState!.save();
                    dprint(_formKey.currentState!.value['item_ref']);
                    // Create empty exhibit if not exists
                    _addItem(
                      _formKey.currentState!.value['exhibit_type'],
                      _formKey.currentState!.value['item_ref'],
                      args!.case_id,
                    ).then((exhibitID) => cameraInit(context).then(
                          (exhibitImage) => cameraFormat(
                            exhibitImage,
                            context,
                            exhibitID,
                            true,
                          ),
                        ));
                    setState(() {
                      _isLoading = false;
                    });
                  } else {
                    rootScaffoldMessengerKey.currentState?.showSnackBar(const SnackBar(
                      backgroundColor: Color.fromARGB(255, 91, 9, 9),
                      content: Text('Missing form fields! Please fill the form out before proceeding.'),
                    ));
                  }
                },
                child: const Text('Add Item')),
          ),
        ],
      ),
    );
  }

  void cameraFormat(XFile? exhibitImage, context, int exhibitID, bool isNew) {
    setState(() {
      _indicatorLoading = true;
    });
    var appPath = "something rnaodm idk";
    final args = ModalRoute.of(context)!.settings.arguments as ExhibitInfoPageArguments;
    var nowUnformatted = DateTime.now().toString().substring(0, 19);
    dprint(nowUnformatted.toString());
    var now = nowUnformatted.toString().replaceAll(':', '-');
    FormattedDocument f;

    String item_ref = _formKey.currentState!.value['item_ref'];

    if (exhibitImage != null) {
      dprint("HEIC Conversion located at ${exhibitImage.path}");
      dprint("Preparing to write modified image...");
      getApplicationDocumentsDirectory().then((value) => {
            Directory("${value.path}/${args.user}/${args.case_ref}/$item_ref").create(recursive: true).then((_) => {
                  // Close the bottom sheet
                  dprint("Folder created"),
                  f = FormattedDocument(
                    exhibitImage.path,
                    args.case_ref,
                    item_ref, // Exhibit Reference needed here
                    now,
                    args.initials,
                  ),
                  dprint("Modified image prepared. Writing..."),
                  appPath = ("${args.user}/${args.case_ref}/$item_ref/$now.jpg"),
                  f.saveTo("${value.path}/$appPath").then((_) => {
                        dprint("Modified image written to $appPath"),

                        // TODO add exhibit contents to ExhibitSQL
                        _contentsAddItem(
                          item_ref, // exhibit_item_ref
                          appPath, // image_path
                          exhibitID.toString(), // exhibit_id
                          args.case_id.toString(), // fk_case_id
                        ),
                        setState(() {
                          _indicatorLoading = false;
                        }),
                        Navigator.pop(context),
                      }),
                })
          });
    } else {
      wprint("Camera closed without taking picture");
      setState(() {
        _indicatorLoading = false;
      });
    }
  }
}

Future<XFile?> cameraInit(context) async {
  var source = ImageSource.camera;
  dprint(MediaQuery.of(context).size.width);
  dprint(MediaQuery.of(context).size.height);
  final XFile? image = await imagePicker.pickImage(
    source: source,
    // maxWidth: MediaQuery.of(context).size.width,
    // maxHeight: MediaQuery.of(context).size.height,
    imageQuality: 50,
    preferredCameraDevice: CameraDevice.rear,
  );
  return image;
}
