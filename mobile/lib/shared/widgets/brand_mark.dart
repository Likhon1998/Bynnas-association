import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({
    super.key,
    this.compact = false,
    this.hero = false,
  });

  final bool compact;
  final bool hero;

  @override
  Widget build(BuildContext context) {
    final logoSize = hero ? 56.0 : (compact ? 36.0 : 48.0);
    final titleSize = hero ? 34.0 : (compact ? 18.0 : 28.0);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: logoSize,
          height: logoSize,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: AppColors.logoGradient,
            borderRadius: BorderRadius.circular(hero ? 16 : (compact ? 11 : 14)),
            boxShadow: [
              BoxShadow(
                color: AppColors.magenta.withValues(alpha: hero ? 0.32 : 0.22),
                blurRadius: hero ? 22 : 14,
                offset: Offset(0, hero ? 10 : 6),
              ),
            ],
          ),
          child: Text(
            'B',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: hero ? 28 : (compact ? 18 : 24),
              height: 1,
            ),
          ),
        ),
        SizedBox(width: compact ? 10 : 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bynnas',
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.navy,
                fontWeight: FontWeight.w800,
                fontSize: titleSize,
                height: 1.02,
                letterSpacing: -0.4,
              ),
            ),
            SizedBox(height: compact ? 1 : 2),
            ShaderMask(
              shaderCallback: (bounds) =>
                  AppColors.brandGradient.createShader(bounds),
              child: Text(
                'ASSOCIATION',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: hero ? 12 : (compact ? 10 : 11),
                  letterSpacing: hero ? 3.2 : (compact ? 1.8 : 2.6),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
