import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final String? badge;
  final bool badgePositive;

  const StatCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    this.badge,
    this.badgePositive = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Adapt font sizes based on available card width
        final isNarrow = constraints.maxWidth < 160;
        final valueFontSize = isNarrow ? 22.0 : 28.0;
        final titleFontSize = isNarrow ? 11.0 : 13.0;

        return ShadCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row: title + icon, title gets all remaining space
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.mutedForeground,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(icon, size: 16, color: theme.colorScheme.mutedForeground),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: valueFontSize,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.foreground,
                  height: 1,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  if (badge != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgePositive
                            ? const Color(0xFFDCFCE7)
                            : const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        badge!,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: badgePositive
                              ? const Color(0xFF16A34A)
                              : const Color(0xFFDC2626),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Flexible(
                    child: Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.mutedForeground,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
