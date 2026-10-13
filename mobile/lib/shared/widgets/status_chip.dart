import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import 'app_format.dart';

class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key});

  final String? status;

  @override
  Widget build(BuildContext context) {
    final key = (status ?? '').toLowerCase();
    final colors = switch (key) {
      'paid' || 'posted' || 'active' || 'published' => (
          bg: const Color(0xFFE8F8EF),
          fg: const Color(0xFF0F7A45),
        ),
      'partial' || 'pending' || 'draft' => (
          bg: const Color(0xFFFFF4E5),
          fg: const Color(0xFFB76E00),
        ),
      'reversed' || 'voided' || 'inactive' || 'archived' => (
          bg: const Color(0xFFFFE8EA),
          fg: const Color(0xFFB42318),
        ),
      _ => (
          bg: AppColors.mist,
          fg: AppColors.navy,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        AppFormat.statusLabel(status),
        style: GoogleFonts.plusJakartaSans(
          color: colors.fg,
          fontWeight: FontWeight.w700,
          fontSize: 11,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
