import 'package:flutter/material.dart';
import '../../theme/saas_palette.dart';

class SidebarNavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const SidebarNavItem({
    super.key,
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<SidebarNavItem> createState() => _SidebarNavItemState();
}

class _SidebarNavItemState extends State<SidebarNavItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bool isSelected = widget.isActive;
    
    // Determine colors based on state
    final Color bgColor = isSelected
        ? SaasPalette.brand50
        : (_isHovered ? SaasPalette.bgSubtle : Colors.transparent);
        
    final Color contentColor = isSelected
        ? SaasPalette.brand600
        : SaasPalette.textSecondary;

    // We keep the left border logic if we want a subtle indicator, 
    // but the design mostly relies on the background and text color.
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  widget.icon,
                  size: 20,
                  color: contentColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.label.replaceAll('\n', ' '), // Flatten text
                    style: TextStyle(
                      color: contentColor,
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
