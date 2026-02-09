import 'package:flutter/material.dart';
import 'package:sukh_app/constants/constants.dart';

/// Displays the app logo based on user's selected icon preference.
/// Use this in place of Image.asset for logo_3.png to support icon variants.
class SelectableLogoImage extends StatelessWidget {
  final double? width;
  final double? height;
  final BoxFit fit;

  const SelectableLogoImage({
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppLogoNotifier.currentIcon,
      builder: (context, iconName, _) {
        final logoPath = AppLogoAssets.getAssetPath(iconName);
        return Image.asset(
          logoPath,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) => Icon(
            Icons.image_not_supported_outlined,
            size: width ?? height ?? 24,
            color: Colors.grey,
          ),
        );
      },
    );
  }
}
