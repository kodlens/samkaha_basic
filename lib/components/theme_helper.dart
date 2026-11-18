import 'package:flutter/material.dart';

class ThemeHelper {

    static InputDecoration inputDecoration(
      String label, {
      String? hint,
      Widget? prefixIcon,
      Widget? suffixIcon,
    }) {
      return InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      );
    }

    static Color primaryColor() {
      return const Color(0xFF1F4D2B);
    }

    static Color primaryMatch() {
      return const Color(0xFF6BAF92);
    }

    static Color darkPrimary() {
      return const Color(0xFF4F8F76);
    }

    static Color lightPrimary() {
      return const Color(0xFFA8D5BA);
    }
    

    static Color backgroundColor() {
      return const Color(0xFFF7F9F7);
    }

    static Color textPrimary() {
      return const Color(0xFF1F2933);
    }

    static Color textSecondary() {
      return const Color(0xFF6B7280);
    }

    static Color success(){
      return const Color(0xFF22C55E);
    }

    static Color warning(){
      return const Color(0xFFF59E0B);
    }

    static Color error(){
      return const Color(0xFFEF4444);
    }

    static Color info(){
      return const Color(0xFF3B82F6);
    }

    static Color cardBackground() {
      return const Color(0xFFFFFFFF);
    }

}  
