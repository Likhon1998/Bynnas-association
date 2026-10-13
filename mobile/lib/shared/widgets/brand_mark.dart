import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({
    super.key,
    this.compact = false,
  });

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final logoSize = compact ? 34.0 : 48.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: logoSize,
          height: logoSize,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: AppColors.logoGradient,
            borderRadius: BorderRadius.circular(compact ? 10 : 14),
            boxShadow: [
              BoxShadow(
                color: AppColors.magenta.withValues(alpha: compact ? 0.18 : 0.28),
                blurRadius: compact ? 10 : 16,
                offset: Offset(0, compact ? 4 : 8),
              ),
            ],
          ),
          child: Text(
            'B',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: compact ? 17 : 24,
              height: 1,
            ),
          ),
        ),
        SizedBox(width: compact ? 9 : 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bynnas',
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.navy,
                fontWeight: FontWeight.w800,
                fontSize: compact ? 17 : 28,
                height: 1.05,
              ),
            ),
            SizedBox(height: compact ? 1 : 2),
            Text(
              'ASSOCIATION',
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
                fontSize: compact ? 9 : 11,
                letterSpacing: compact ? 1.8 : 2.8,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
