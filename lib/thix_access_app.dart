import 'package:flutter/material.dart';

import 'shared/router/app_router.dart';
import 'shared/theme/app_theme.dart';

class ThixAccessApp extends StatelessWidget {
  const ThixAccessApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'THIX ACCESS',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const AppRouter(),
      );
}
