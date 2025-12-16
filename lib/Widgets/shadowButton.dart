// ignore_for_file: must_be_immutable

import 'package:classinsight/utils/AppColors.dart';
import 'package:classinsight/utils/fontStyles.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ShadowButton extends StatelessWidget {
  String text;
  void Function()? onTap;
  IconData? icon;
  Color? backgroundColor;
  Color? textColor;
  
  ShadowButton({
    required this.text,
    required this.onTap,
    this.icon,
    this.backgroundColor,
    this.textColor,
    super.key});

 
  @override
  Widget build(BuildContext context) {
    double screenHeight =  MediaQuery.of(context).size.height;
    double screenWidth =  MediaQuery.of(context).size.width;
    late double height;

    if (screenWidth > 350 && screenWidth <= 400) {
      height = 60;
    } else if (screenWidth > 400 && screenWidth <= 500) {
      height = 70;
    } else if (screenWidth > 500 && screenWidth <= 768) {
      height = 90;
    }else if(screenWidth>768){
      height = 100;
    } 
    else {
      height = 50; // Default height for other screen sizes
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppColors.borderRadiusMedium),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppColors.spacingMD,
            vertical: AppColors.spacingSM,
          ),
          width: screenWidth*0.4,
          height: height,
          decoration: BoxDecoration(
            color: backgroundColor ?? AppColors.appLightBlue,
            borderRadius: BorderRadius.circular(AppColors.borderRadiusMedium),
            boxShadow: AppColors.cardShadow,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  color: textColor ?? AppColors.textPrimary,
                  size: 20,
                ),
                SizedBox(width: AppColors.spacingSM),
              ],
              Flexible(
                child: Text(
                  text,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textColor ?? AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}