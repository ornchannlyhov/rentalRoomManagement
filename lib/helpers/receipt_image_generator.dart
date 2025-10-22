import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:receipts_v2/data/models/receipt.dart';
import 'package:receipts_v2/presentation/view/screen/receipt/widgets/receipt_detail.dart';
import 'package:screenshot/screenshot.dart';

class ReceiptImageGenerator {
  static final ScreenshotController _screenshotController = ScreenshotController();

  static Future<Uint8List?> generateReceiptImage(Receipt receipt) async {
    final completer = Completer<Uint8List?>();
    
    void capture() {
      _screenshotController.capture().then((Uint8List? image) {
        completer.complete(image);
      }).catchError((onError) {
        completer.completeError(onError);
      });
    }

    runZonedGuarded(() {
      final captured = Screenshot(
        controller: _screenshotController,
        child: MaterialApp( 
          home: ReceiptDetailScreen(
            receipt: receipt,
            onShareRequested: capture, 
          ),
        ),
      );

      final binding = WidgetsFlutterBinding.ensureInitialized();
      binding.attachRootWidget(captured);
    }, (error, stack) {
      completer.completeError(error);
    });

    return completer.future;
  }
}