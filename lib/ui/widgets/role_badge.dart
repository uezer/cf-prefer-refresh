import 'package:flutter/material.dart';

import '../../l10n.dart';
import '../../models/enums.dart';
import '../../theme.dart';

class RoleBadge extends StatelessWidget {
  const RoleBadge({
    super.key,
    required this.role,
    this.compact = false,
    this.onDark = false,
  });

  final AppRole role;
  final bool compact;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final publisher = role == AppRole.publisher;
    final label = publisher
        ? (compact ? S.rolePublisher : '当前角色：${S.rolePublisher}  ·  ${S.rolePublisherEn}')
        : (compact ? S.roleSubscribe : '当前角色：${S.roleSubscribe}  ·  ${S.roleSubscribeEn}');
    final bg = publisher ? AppColors.rust : AppColors.pine;
    if (onDark) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: bg,
            fontWeight: FontWeight.w800,
            fontSize: compact ? 12 : 13,
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: bg.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: bg,
          fontWeight: FontWeight.w700,
          fontSize: compact ? 12 : 13,
        ),
      ),
    );
  }
}
