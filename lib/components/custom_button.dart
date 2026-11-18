import 'package:flutter/material.dart';
import 'package:sales_management/components/theme_helper.dart';

Widget customButton(void Function() onPressed, String label) {
  return ElevatedButton.icon(
    onPressed: onPressed,
    icon: const Icon(Icons.add, color: Colors.white),
    label: Text(
      label,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    ),
    style: ElevatedButton.styleFrom(
      backgroundColor: ThemeHelper.primaryColor(), // flat teal
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0, // remove shadow for flat look
    ),
  );
}