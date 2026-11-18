import 'package:flutter/material.dart';

class MyTextSample {
  // Example: headline style
  static TextStyle? headline(BuildContext context) {
    return Theme.of(context).textTheme.titleLarge;
  }

  // Example: subhead style
  static TextStyle? subhead(BuildContext context) {
    return Theme.of(context).textTheme.titleMedium;
  }

  // Example: body style
  static TextStyle? body(BuildContext context) {
    return Theme.of(context).textTheme.bodyMedium;
  }

  // Example: caption style
  static TextStyle? caption(BuildContext context) {
    return Theme.of(context).textTheme.bodySmall;
  }

// You can add more custom styles here
}
