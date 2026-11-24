import 'package:flutter/material.dart';

import '../../features/conversation/presentation/conversation_page.dart';
import '../../features/home/presentation/home_page.dart';

class AppRouter extends StatelessWidget {
  const AppRouter({super.key});

  @override
  Widget build(BuildContext context) => Navigator(
        onGenerateRoute: (settings) => MaterialPageRoute<void>(
          builder: (_) => settings.name == '/conversation'
              ? const ConversationPage()
              : const HomePage(),
        ),
      );
}
