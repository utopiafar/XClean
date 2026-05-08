import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';
import 'app.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // TODO: Implement auto clean worker
    return true;
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Workmanager().initialize(callbackDispatcher);

  runApp(const XCleanApp());
}
