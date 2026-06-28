import 'package:flutter/material.dart';

class FeatureCard extends StatelessWidget {
  const FeatureCard({required this.title, required this.description, this.icon, super.key});

  final String title;
  final String description;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon ?? Icons.star_outline),
        title: Text(title),
        subtitle: Text(description),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
