import 'package:flutter/material.dart';

class AppStatusChip extends StatelessWidget {
  const AppStatusChip({required this.label, this.active = false, super.key});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) => Chip(
        avatar: Icon(
          active ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 18,
          color: active ? Colors.green : null,
        ),
        label: Text(label),
      );
}
