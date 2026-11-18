
import 'package:flutter/material.dart';
import 'package:sales_management/components/theme_helper.dart';

Widget headerText(String text) {
  return Text(
    text,
    style: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w900,
      //color: Color.fromARGB(255, 201, 205, 253),
      color: ThemeHelper.textPrimary(),
    ),
  );
}