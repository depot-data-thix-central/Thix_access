import 'package:flutter/material.dart';

import '../../../shared/widgets/app_status_chip.dart';

class ConversationPage extends StatefulWidget {
  const ConversationPage({super.key});

  @override
  State<ConversationPage> createState() => _ConversationPageState();
}

class _ConversationPageState extends State<ConversationPage> {
  bool _microphoneEnabled = false;
  bool _paused = false;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Conversation'),
          leading: IconButton(
            tooltip: 'Terminer la conversation',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  children: [
                    AppStatusChip(label: 'Caméra — à connecter'),
                    AppStatusChip(label: 'Reconnaissance — à connecter'),
                    AppStatusChip(label: 'Avatar — à connecter'),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Card(
                      margin: const EdgeInsets.all(16),
                      child: const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.person_outline, size: 72),
                              SizedBox(height: 12),
                              Text('Zone de l’avatar / aperçu caméra'),
                              SizedBox(height: 8),
                              Text('Aucune traduction active dans ce squelette.'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  children: [
                    FilledButton.tonalIcon(
                      onPressed: () => setState(
                          () => _microphoneEnabled = !_microphoneEnabled),
                      icon: Icon(_microphoneEnabled ? Icons.mic : Icons.mic_off),
                      label: Text(_microphoneEnabled ? 'Couper le micro' : 'Activer le micro'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => setState(() => _paused = !_paused),
                      icon: Icon(_paused ? Icons.play_arrow : Icons.pause),
                      label: Text(_paused ? 'Reprendre' : 'Pause'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}
