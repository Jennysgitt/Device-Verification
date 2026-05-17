import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lightmode/core/theme/app_colors.dart';

class CustomButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool isFullWidth;

  const CustomButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.isFullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    final style = ElevatedButton.styleFrom(
      backgroundColor: backgroundColor ?? AppColors.primary,
      foregroundColor: foregroundColor ?? Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) Icon(icon, size: 20),
        if (icon != null) const SizedBox(width: 12),
        Text(
          label,
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );

    if (isFullWidth) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(onPressed: onPressed, style: style, child: content),
      );
    }

    return ElevatedButton(onPressed: onPressed, style: style, child: content);
  }
}
