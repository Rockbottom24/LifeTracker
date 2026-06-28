import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';

class FormTabletGrid extends StatelessWidget {
  const FormTabletGrid({
    super.key,
    required this.leftColumn,
    required this.rightColumn,
  });

  final List<Widget> leftColumn;
  final List<Widget> rightColumn;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Column(children: leftColumn)),
        const SizedBox(width: AppSpacing.sectionGap),
        Expanded(child: Column(children: rightColumn)),
      ],
    );
  }
}

class FormTabletTwoRowGrid extends StatelessWidget {
  const FormTabletTwoRowGrid({
    super.key,
    required this.topLeft,
    required this.topRight,
    required this.bottomLeft,
    required this.bottomRight,
  });

  final Widget topLeft;
  final Widget topRight;
  final Widget bottomLeft;
  final Widget bottomRight;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FormTabletGrid(leftColumn: [topLeft], rightColumn: [topRight]),
        FormTabletGrid(leftColumn: [bottomLeft], rightColumn: [bottomRight]),
      ],
    );
  }
}
