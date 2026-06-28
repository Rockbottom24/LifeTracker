import 'package:flutter/material.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({required this.title, required this.child, this.actions = const [], super.key});

  final String title;
  final Widget child;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: actions,
      ),
      body: SafeArea(child: child),
    );
  }
}
