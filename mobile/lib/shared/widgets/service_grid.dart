import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import 'app_motion.dart';

class ServiceItem {
  const ServiceItem({
    required this.icon,
    required this.label,
    required this.tint,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final String label;
  final Color tint;
  final VoidCallback onTap;
  final String? badge;
}

/// Single card of evenly spaced service buttons — no category headers.
class ServiceGrid extends StatelessWidget {
  const ServiceGrid({
    super.key,
    required this.items,
    this.columns = 4,
  });

  final List<ServiceItem> items;
  final int columns;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 16, 10, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.fieldBorder.withValues(alpha: 0.9)),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.045),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          mainAxisSpacing: 12,
          crossAxisSpacing: 4,
          childAspectRatio: 0.78,
        ),
        itemBuilder: (context, index) {
          return FadeRise(
            delay: Duration(milliseconds: 40 + (index.clamp(0, 11) * 28)),
            child: _ServiceButton(item: items[index]),
          );
        },
      ),
    );
  }
}

class _ServiceButton extends StatelessWidget {
  const _ServiceButton({required this.item});

  final ServiceItem item;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: item.onTap,
      scale: 0.92,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: item.tint.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(
                    color: item.tint.withValues(alpha: 0.16),
                  ),
                ),
                child: Icon(item.icon, color: item.tint, size: 25),
              ),
              if (item.badge != null)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    height: 16,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.magenta,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Text(
                      item.badge!,
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 9,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            item.label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              color: AppColors.navy,
              fontWeight: FontWeight.w700,
              fontSize: 11,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
