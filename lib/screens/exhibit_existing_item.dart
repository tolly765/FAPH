// ignore_for_file: unused_element, unused_local_variable, avoid_print

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../services/exhibit_item_sql_helper.dart';
import '../services/fact_debug.dart';
import '../services/image_overlayer.dart';
import '../services/exhibit_sql_helper.dart';

final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();
ExistingItemPageArguments? args;
final stopwatch = Stopwatch();

var imagePicker;

class ExistingItemPage extends StatefulWidget {
  const ExistingItemPage({Key? key}) : super(key: key);

  //Define routename
  static const routeName = '/case/items/existingItem/extractArguments';

  @override
  _ExistingItemPageState createState() => _ExistingItemPageState();
}

// Define argument variables from route
// Required: Case Reference/ID, itemID
class ExistingItemPageArguments {
  // final String itemtype; // Case ref
  final String itemref; // Case asignee
  final int fkExhibitID;
  final String itemtype;
  final String caseID; // Case ID
  final String initials;
  final String case_ref;
  final String user;

  ExistingItemPageArguments(
    // this.itemtype, // Case ref
    this.itemref, // Case asignee
    this.fkExhibitID,
    this.itemtype,
    this.caseID, // Case ID
    this.initials,
    this.case_ref,
    this.user,
  );
}

class _ExistingItemPageState extends State<ExistingItemPage> with RouteAware {
  final _formKey = GlobalKey<FormBuilderState>();
  // All journals
  List<Map<String, dynamic>> _journals = [];
  List<Map<String, dynamic>> _exhibitJournal = [];

  bool _isLoading = false;
  bool _indicatorLoading = false;
  final bool addButtonEnable = false;
  String loadingText = "Loading...";

  // This function is used to fetch all data from the database
  void _refreshJournals() async {
    final data = await ExhibitSQLHelper.getItem((args != null) ? args!.caseID : '');

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
        args = ModalRoute.of(context)!.settings.arguments as ExistingItemPageArguments;
      });
      _refreshJournals(); // Loading the diary when the app starts
    });
  }

  Future<int?> _getItemCount() async {
    int? itemCount = await ExhibitSQLHelper.getItemCount(args!.caseID);
    return itemCount;
  }

  Future<int> _getFKExhibitID(item_id) async {
    final data = await ExhibitSQLHelper.getItem(item_id);
    eprint(data[0]['item_id']);
    return data[0]['item_id'];
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
      exhibitID.toString(), // exhibitID
      caseID, // Case ID
    );
    dprint('Item created on table "exhibit_contents": $itemref $imgpath $caseID');
    _refreshJournals();
  }

  var _image;

  // Widget builder for the inner UI
  @override
  Widget build(BuildContext context) {
    /* final args_ =
        ModalRoute.of(context)!.settings.arguments as CaseViewScreenArguments; */
    imagePicker = ImagePicker();
    final args = ModalRoute.of(context)!.settings.arguments as ExistingItemPageArguments;
    return Stack(children: [
      FutureBuilder(
        future: ExhibitItemSQLHelper.getExhibitItemCount(args.fkExhibitID),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            dprint("Snapshot Data: ${snapshot.data}");
            int count = snapshot.data as int;
            return Scaffold(
              appBar: AppBar(
                title: const Text('Add an exhibit'),
              ),
              body: Center(
                child: ElevatedButton(
                    onPressed: () {
                      cameraInit(context).then(
                        (exhibitImage) => cameraFormat(
                          exhibitImage,
                          context,
                          args.fkExhibitID,
                          count,
                          true,
                        ),
                      );
                    },
                    child: const Text('Enable camera')),
              ),
              // TODO Get Camera working on immediate call
            );
          } else {
            return CircularProgressIndicator();
          }
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

  void cameraFormat(XFile? exhibitImage, context, int exhibitID, int count, bool isNew) {
    setState(() {
      _indicatorLoading = true;
    });
    var appPath = "something rnaodm idk";
    final args = ModalRoute.of(context)!.settings.arguments as ExistingItemPageArguments;
    var nowUnformatted = DateTime.now().toString().substring(0, 19);
    dprint(nowUnformatted.toString());
    var now = nowUnformatted.toString().replaceAll(':', '-');
    FormattedDocument f;

    String itemRef = args.itemref;

    if (exhibitImage != null) {
      dprint("HEIC Conversion located at ${exhibitImage.path}");
      dprint("Preparing to write modified image...");
      getApplicationDocumentsDirectory().then((value) => {
            Directory("${value.path}/${args.user}/${args.case_ref}/$itemRef").create(recursive: true).then((_) => {
                  // Close the bottom sheet
                  dprint("Folder created"),
                  f = FormattedDocument(
                    exhibitImage.path,
                    args.case_ref,
                    "$itemRef", // Exhibit Reference needed here
                    now,
                    args.initials,
                  ),
                  dprint("Modified image prepared. Writing..."),
                  appPath = ("${args.user}/${args.case_ref}/$itemRef/${args.case_ref}_${exhibitID}_$now.jpg"),
                  f.saveTo("${value.path}/$appPath").then((_) => {
                        dprint("Modified image written to $appPath"),

                        // TODO add exhibit contents to ExhibitSQL
                        _contentsAddItem(
                          itemRef, // exhibit_item_ref
                          appPath, // image_path
                          exhibitID, // exhibit_id
                          args.caseID.toString(), // fk_case_id
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
  final XFile? image = await imagePicker.pickImage(
    source: source,
    // maxWidth: MediaQuery.of(context).size.width,
    // maxHeight: MediaQuery.of(context).size.height,
    imageQuality: 50,
    preferredCameraDevice: CameraDevice.rear,
  );
  return image;
}
