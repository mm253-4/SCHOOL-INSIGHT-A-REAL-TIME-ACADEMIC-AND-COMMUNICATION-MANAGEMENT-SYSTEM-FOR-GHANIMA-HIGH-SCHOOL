import 'package:flutter/material.dart';
import 'package:classinsight/utils/AppColors.dart';

class ModernCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final LinearGradient? gradient;
  final double? borderRadius;
  final List<BoxShadow>? boxShadow;
  final bool isElevated;

  const ModernCard({
    Key? key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.gradient,
    this.borderRadius,
    this.boxShadow,
    this.isElevated = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? EdgeInsets.zero,
      decoration: BoxDecoration(
        color: gradient == null ? (backgroundColor ?? Colors.white) : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius ?? AppColors.borderRadiusLarge),
        boxShadow: isElevated 
            ? (boxShadow ?? AppColors.cardShadow)
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius ?? AppColors.borderRadiusLarge),
          child: Padding(
            padding: padding ?? EdgeInsets.all(AppColors.spacingMD),
            child: child,
          ),
        ),
      ),
    );
  }
}

