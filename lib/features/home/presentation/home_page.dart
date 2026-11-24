import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('THIX ACCESS')),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.accessibility_new, size: 72),
                  const SizedBox(height: 20),
                  Text('Communiquons autrement',
                      style: Theme.of(context).textTheme.headlineMedium,
                      textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  const Text(
                    'Un assistant de communication accessible. Les fonctions de traduction seront disponibles après validation des fournisseurs et de la langue des signes ciblée.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context).pushNamed('/conversation'),
                    icon: const Icon(Icons.forum_outlined),
                    label: const Text('Démarrer une conversation'),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.settings_outlined),
                    label: const Text('Paramètres — à venir'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
