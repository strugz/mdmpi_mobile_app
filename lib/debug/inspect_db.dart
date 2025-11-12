import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/data/local/database_helper.dart';

/// Debug entrypoint: prints counts and some metadata for the signature/image tables.
/// Run with:
///   flutter run -t lib/debug/inspect_db.dart -d <deviceId>

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final helper = DatabaseHelper.instance;

    final dao = await helper.requestDao;

    final sigs = await dao.getAllReceiverSignatures();
    final imgs = await dao.getAllRequestImages();

    print('=== DB inspection start ===');
    print('Receiver signatures count: ${sigs.length}');
    for (var row in sigs) {
      final id = row['RequestID'];
      final val = row['RequestReceiverSignature'] as String?;
      print('sig row: RequestID=$id, bytesLength=${val?.length ?? 0}');
    }

    print('Request images count: ${imgs.length}');
    for (var row in imgs) {
      final id = row['RequestID'];
      final val = row['RequestImage'] as String?;
      print('img row: RequestID=$id, bytesLength=${val?.length ?? 0}');
    }

    print('=== DB inspection done ===');
  } catch (e, st) {
    print('Error inspecting DB: $e');
    print(st);
  } finally {
    // Quit the app after printing
    exit(0);
  }
}

