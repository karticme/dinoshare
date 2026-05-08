import 'package:dinoshare/style/typography.dart';
import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:dinoshare/util/platform_asset.dart';

import '../style/theme.dart';

class LThemeSwitcher extends StatelessWidget {
  const LThemeSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final lCustom = dinoCustomColors(
      dark: theme.colors.brightness == Brightness.dark,
    );

    final themeController = AppThemeProvider.of(context);
    final currentTheme = themeController.mode;

    const themes = ['Light', 'Dark', 'System'];
    const themeImages = [
      'Theme_Light.png',
      'Theme_Dark.png',
      'Theme_System.png',
    ];
    const themeModes = [
      AppThemeMode.light,
      AppThemeMode.dark,
      AppThemeMode.system,
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        spacing: 12,
        children: [
          for (int i = 0; i < themes.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => themeController.mode = themeModes[i],
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 8,
                  children: [
                    AspectRatio(
                      aspectRatio: 1.3333,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border:
                              themeModes[i] == currentTheme
                                  ? Border.all(color: lCustom.success, width: 2)
                                  : Border.all(color: theme.colors.border),
                          boxShadow: [
                            BoxShadow(
                              color: Color.fromRGBO(0, 0, 0, 0.02),
                              offset: Offset(1, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12.5),
                          child: Image(
                            image: AssetImage(platformAsset(themeImages[i])),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    DText(
                      themes[i],
                      size: DTextSize.sm,
                      color:
                          themeModes[i] == currentTheme
                              ? lCustom.success
                              : theme.colors.mutedForeground,
                      weight: FontWeight.w500,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
