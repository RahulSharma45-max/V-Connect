import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:google_fonts/google_fonts.dart';
import 'package:v_connect/theme/app_theme.dart';

/// App bar with the portal's blue gradient. Drop-in replacement for [AppBar].
class VAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final bool centerTitle;
  final double? titleSpacing;
  final PreferredSizeWidget? bottom;

  const VAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.centerTitle = false,
    this.titleSpacing,
    this.bottom,
  });

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      foregroundColor: AppColors.onPrimary,
      elevation: 0,
      flexibleSpace: Container(
        decoration: const BoxDecoration(gradient: AppColors.headerGradient),
      ),
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      centerTitle: centerTitle,
      titleSpacing: titleSpacing,
      title:
          titleWidget ??
          (title == null
              ? null
              : Text(
                  title!,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 19,
                    color: AppColors.onPrimary,
                  ),
                )),
      actions: actions,
      bottom: bottom,
    );
  }
}

/// The "V-CONNECT / CAMPUS PORTAL" wordmark used in the main header.
class VBrandMark extends StatelessWidget {
  final double logoSize;

  const VBrandMark({super.key, this.logoSize = 34});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: logoSize,
          height: logoSize,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: AppColors.onPrimary,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.onPrimary.withOpacity(0.6)),
          ),
          child: ClipOval(
            child: Image.asset('assets/app_icon.png', fit: BoxFit.cover),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'V-CONNECT',
              style: GoogleFonts.merriweather(
                color: AppColors.onPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                height: 1.0,
              ),
            ),
            Text(
              'CAMPUS PORTAL',
              style: GoogleFonts.merriweather(
                color: AppColors.onPrimary,
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.6,
                height: 1.3,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// White panel with a coloured top rule and a tinted header strip,
/// modelled on the portal's "Spotlight" panels.
class VSectionCard extends StatelessWidget {
  final String? title;
  final IconData? icon;
  final Widget? trailing;
  final Widget child;
  final Color accent;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;

  const VSectionCard({
    super.key,
    this.title,
    this.icon,
    this.trailing,
    required this.child,
    this.accent = AppColors.maroon,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.fromLTRB(16, 0, 16, 16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border(top: BorderSide(color: accent, width: 2)),
        boxShadow: vCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null)
            Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
              color: AppColors.surfaceAlt,
              child: Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18, color: accent),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      title!,
                      style: GoogleFonts.inter(
                        color: accent,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  ?trailing,
                ],
              ),
            ),
          Padding(padding: padding, child: child),
        ],
      ),
    );
  }
}

/// Small "More ..." style link used in section headers.
class VHeaderLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color color;

  const VHeaderLink({
    super.key,
    required this.label,
    required this.onTap,
    this.color = AppColors.maroon,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        minimumSize: const Size(0, 32),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(label, style: GoogleFonts.inter(fontSize: 13)),
    );
  }
}

/// Portal module tile: coloured top border, illustration icon, coloured
/// label and a square "enter" button.
class VModuleTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String? badge;

  const VModuleTile({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border(top: BorderSide(color: color, width: 2)),
        boxShadow: vCardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 26),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: color,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 30,
                            height: 26,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: const Icon(
                              Icons.login,
                              size: 15,
                              color: AppColors.onPrimary,
                            ),
                          ),
                          if (badge != null)
                            Positioned(
                              right: -10,
                              top: -8,
                              child: VCountBadge(label: badge!),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Red pill badge, as on the portal's notification counters.
class VCountBadge extends StatelessWidget {
  final String label;

  const VCountBadge({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      constraints: const BoxConstraints(minWidth: 18),
      decoration: BoxDecoration(
        color: AppColors.danger,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.surface, width: 1.5),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
          color: AppColors.onPrimary,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Present / absent pill.
class VStatusChip extends StatelessWidget {
  final bool isPresent;
  final bool compact;

  const VStatusChip({super.key, required this.isPresent, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final color = isPresent ? AppColors.success : AppColors.danger;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 3 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPresent ? Icons.check_circle : Icons.cancel,
            color: color,
            size: compact ? 12 : 16,
          ),
          SizedBox(width: compact ? 4 : 6),
          Text(
            isPresent ? 'PRESENT' : 'ABSENT',
            style: GoogleFonts.inter(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: compact ? 10 : 12,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// Circular avatar that falls back to the first initial.
class VAvatar extends StatelessWidget {
  final String? photoUrl;
  final String name;
  final double radius;
  final IconData? fallbackIcon;

  const VAvatar({
    super.key,
    required this.name,
    this.photoUrl,
    this.radius = 22,
    this.fallbackIcon,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUrl != null && photoUrl!.isNotEmpty;
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';
    final fallback = Center(
      child: fallbackIcon != null
          ? Icon(fallbackIcon, color: AppColors.primary, size: radius)
          : Text(
              initial,
              style: GoogleFonts.inter(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: radius * 0.8,
              ),
            ),
    );
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primary.withOpacity(0.12),
      child: ClipOval(
        child: hasPhoto
            ? Image.network(
                photoUrl!,
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => fallback,
              )
            : fallback,
      ),
    );
  }
}

/// Icon + message placeholder for empty lists.
class VEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;

  const VEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: AppColors.textMuted.withOpacity(0.6)),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: AppColors.textMuted,
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Grey drag handle at the top of bottom sheets.
class VSheetHandle extends StatelessWidget {
  const VSheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

/// Thin gradient footer bar with the copyright line.
class VFooter extends StatelessWidget {
  const VFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: const BoxDecoration(gradient: AppColors.headerGradient),
      child: Text(
        'Copyright © ${DateTime.now().year} V-Connect · Campus Communication Platform',
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(color: AppColors.onPrimary, fontSize: 11),
      ),
    );
  }
}

/// Soft drop shadow shared by cards and tiles.
const List<BoxShadow> vCardShadow = [
  BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 2)),
];

/// Snack bar in the portal style.
void showVSnackBar(
  BuildContext context,
  String message, {
  bool isError = false,
}) {
  ScaffoldMessenger.of(context)
    ..removeCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(color: AppColors.onPrimary),
        ),
        backgroundColor: isError ? AppColors.danger : AppColors.success,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    );
}
