import 'dart:async';
import 'dart:convert';
import 'dart:io' show Directory, File, FileSystemException, Platform;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;

import 'fact_debug.dart';

final stopwatch = Stopwatch();

class FormattedDocument {
  final double padding = 200;
  final String caseRef;
  final String exhibitRef;
  final String dateTime;
  final String initials;
  late ui.PictureRecorder recorder;
  late ui.Canvas canvas;
  late Uint8List imageFile;
  late ui.Size size;

  FormattedDocument(
    String imagePath,
    this.caseRef,
    this.exhibitRef,
    this.dateTime,
    this.initials,
  ) {
    recorder = ui.PictureRecorder();
    imageFile = File(imagePath).readAsBytesSync();
    final image = img.decodeImage(imageFile)!;
    size = Size(
      image.width.toDouble(),
      image.height.toDouble() + padding,
    );

    canvas = Canvas(
      recorder,
      Rect.fromPoints(
        const Offset(0.0, 0.0),
        Offset(
          size.width,
          size.height,
        ),
      ),
    );
  }

  Future<ui.Picture> draw() async {
    final paintGrey = Paint()
      ..color = Colors.grey.shade800
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(0.0, 0.0, size.width, size.height),
      paintGrey,
    );
    final completer = Completer<ui.Image>();

    ui.decodeImageFromList(imageFile, completer.complete);
    canvas.drawImage(
      await completer.future,
      const Offset(0.0, 0.0),
      Paint(),
    );

    const textStyle = TextStyle(
      color: Colors.white,
      fontSize: 60,
      fontFamily: 'Noto',
    );

    drawText(caseRef, textStyle, 4, 1);
    drawText(exhibitRef, textStyle, 4, 2);
    drawText(dateTime, textStyle, 4, 3);
    drawText(initials, textStyle, 4, 4);

    return recorder.endRecording();
  }

  void drawText(String text, TextStyle textStyle, int textBoxes, int box) {
    final textSpan = TextSpan(text: text, style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    final boxWidth = (size.width / textBoxes);
    textPainter.layout(
      minWidth: 0,
      maxWidth: boxWidth - padding * 0.1,
    );
    final offset = boxWidth * (box - 1);
    textPainter.paint(
        canvas,
        Offset(
          (boxWidth - textPainter.width) * 0.5 + offset,
          size.height - (padding + textPainter.height) * 0.5,
        ));
  }

  saveTo(String path) async {
    stopwatch.reset();
    stopwatch.start();
    dprint("Current Time Elapsed: ${stopwatch.elapsedMilliseconds}");
    wprint("Drawing image...");

    final picture = await draw();
    final created_image = await picture.toImage(
      size.width.toInt(),
      size.height.toInt(),
    );

    eprint("Image drawn");
    dprint("Current Time Elapsed: ${stopwatch.elapsedMilliseconds}");

    wprint("Converting image to buffer_list...");
    final data = await created_image.toByteData(format: ui.ImageByteFormat.rawRgba);

    eprint("Image converted to byte_data");
    dprint("Current Time Elapsed: ${stopwatch.elapsedMilliseconds}");

    final buffer = data?.buffer.asUint8List();

    // wprint("Converting image to buffer_list...");
    // final data = await created_image.toByteData(format: ui.ImageByteFormat.jpg); // Offending line for speed
    // final buffer = data?.buffer;
    // final buffer_list = buffer!.asUint8List(
    //   data!.offsetInBytes,
    //   data.lengthInBytes,
    // );

    // Convert and save the image to a file

    eprint("Byte_data converted to buffer list");
    dprint("Current Time Elapsed: ${stopwatch.elapsedMilliseconds}");

    wprint("Encoding JPEG...");
    //final ImageData = img.encodeJpg(img.decodePng(buffer!)!, quality: 90);
    img.Image decoded = img.Image.fromBytes(size.width.toInt(), size.height.toInt(), buffer!, format: img.Format.rgba);
    List<int> ImageData = img.encodeJpg(decoded, quality: 90);

    eprint("Image encoded to JPEG");

    await File(path).writeAsBytes(ImageData);
    stopwatch.stop();
    dprint("Current Time Elapsed: ${stopwatch.elapsedMilliseconds}");
    return true;
  }
}
