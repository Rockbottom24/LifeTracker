import 'package:flutter/material.dart';

class StatCard extends StatelessWidget {
  const StatCard({required this.title, required this.value, super.key});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 8),
              Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}
