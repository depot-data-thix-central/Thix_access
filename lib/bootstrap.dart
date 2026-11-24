import 'package:flutter/widgets.dart';

import 'thix_access_app.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ThixAccessApp());
}
