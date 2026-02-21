import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../models/task_model.dart';

class TaskCard extends StatefulWidget {
  final HeroTask task;
  final VoidCallback? onAccept;
  final VoidCallback? onTap;

  const TaskCard({
    super.key,
    required this.task,
    this.onAccept,
    this.onTap,
  });

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final task = widget.task;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _hovered ? 1.01 : 1.0,
          duration: const Duration(milliseconds: 150),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.card,
              border: Border.all(
                color: _hovered
                    ? theme.colorScheme.primary.withValues(alpha: 0.3)
                    : theme.colorScheme.border,
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: _hovered
                  ? [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(alpha: 0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      )
                    ]
                  : [],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.foreground,
                        ),
                      ),
                    ),
                    if (task.urgency == TaskUrgency.urgent)
                      _urgencyBadge()
                    else if (task.urgency == TaskUrgency.emergency)
                      _urgencyBadge(emergency: true)
                    else
                      ShadBadge.secondary(child: Text(task.category.label)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  task.description,
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.mutedForeground,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _chip(theme, LucideIcons.dollarSign,
                        '\$${task.compensation.toStringAsFixed(2)}',
                        highlight: true),
                    const SizedBox(width: 12),
                    _chip(theme, LucideIcons.clock,
                        '${task.estimatedMinutes}min'),
                    const SizedBox(width: 12),
                    Flexible(
                      child: _chip(
                        theme,
                        LucideIcons.mapPin,
                        task.delivery.short,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ShadAvatar(
                      task.posterAvatarUrl,
                      size: const Size(22, 22),
                      placeholder: Text(task.posterName.isNotEmpty ? task.posterName[0] : '?'),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      task.posterName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.foreground,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(LucideIcons.star, size: 11, color: Colors.amber),
                    Text(
                      task.posterRating.toString(),
                      style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.mutedForeground),
                    ),
                    const Spacer(),
                    Text(
                      task.timeAgo,
                      style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.mutedForeground),
                    ),
                    if (task.status == TaskStatus.open &&
                        widget.onAccept != null) ...[
                      const SizedBox(width: 12),
                      ShadButton(
                        size: ShadButtonSize.sm,
                        leading: const Icon(LucideIcons.zap, size: 14),
                        child: const Text('Accept'),
                        onPressed: widget.onAccept,
                      ),
                    ],
                    if (task.status == TaskStatus.accepted)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'In Progress',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF16A34A),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _urgencyBadge({bool emergency = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        emergency ? 'EMERGENCY' : 'URGENT',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Color(0xFFDC2626),
        ),
      ),
    );
  }

  Widget _chip(ShadThemeData theme, IconData icon, String label,
      {bool highlight = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon,
            size: 13,
            color: highlight
                ? theme.colorScheme.primary
                : theme.colorScheme.mutedForeground),
        const SizedBox(width: 3),
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: highlight ? FontWeight.w600 : FontWeight.w400,
              color: highlight
                  ? theme.colorScheme.primary
                  : theme.colorScheme.mutedForeground,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
