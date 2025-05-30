import 'package:flutter/material.dart';

class ResponsiveScaffold extends StatelessWidget {
  final Widget mobileBody;
  final Widget webBody;

  const ResponsiveScaffold({
    super.key,
    required this.mobileBody,
    required this.webBody,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return mobileBody;
        } else {
          return webBody;
        }
      },
    );
  }
}
