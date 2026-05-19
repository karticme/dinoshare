import 'dart:io';
import 'package:dinoshare/style/svgs.dart';
import 'package:dinoshare/style/typography.dart';
import 'package:dinoshare/util/utility_function.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:forui/forui.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:dinoshare/state/state_index.dart';
import 'package:dinoshare/widgets/button.dart';
import 'package:dinoshare/widgets/header.dart';
import 'package:dinoshare/widgets/items.dart';
import 'package:dinoshare/widgets/switch.dart';
import 'package:dinoshare/widgets/theme_switcher.dart';
import 'package:url_launcher/url_launcher.dart';

import '../style/theme.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  late TextEditingController _nameController;

  static const _unitOptions = DataUnitType.values;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: appDeviceName.value);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickReceiveFolder() async {
    final path = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Choose receive folder',
    );
    if (path != null && path.trim().isNotEmpty) {
      await setReceivePath(path.trim());
      if (mounted) setState(() {});
    }
  }

  Future<void> _openSponsorLink(String url) async {
    final uri = Uri.parse(url);

    if (Platform.isMacOS) {
      await Process.start('open', [url]);
      return;
    }
    if (Platform.isLinux) {
      await Process.start('xdg-open', [url]);
      return;
    }
    if (Platform.isWindows) {
      await Process.start('cmd', ['/c', 'start', '', url]);
      return;
    }

    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        // ignore: avoid_print
        print('Could not open sponsor link: $uri');
      }
    } catch (err) {
      // ignore: avoid_print
      print('Failed to launch URL with url_launcher: $err');
    }
  }

  void _showUnitPicker() {
    showFSheet(
      side: FLayout.btt,
      context: context,
      mainAxisMaxRatio: null,
      builder: (ctx) {
        final theme = ctx.theme;
        final lCustom = dinoCustomColors(
          dark: theme.colors.brightness == Brightness.dark,
        );
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.4,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder:
              (ctx2, controller) => Container(
                decoration: BoxDecoration(
                  color: theme.colors.secondary,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                  border: Border.all(
                    color: theme.colors.border,
                    strokeAlign: BorderSide.strokeAlignOutside,
                  ),
                ),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  spacing: 12,
                  children: [
                    Container(
                      width: 52,
                      height: 6,
                      decoration: BoxDecoration(
                        color: theme.colors.border,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        controller: controller,
                        children: [
                          Padding(
                            padding: EdgeInsetsGeometry.fromLTRB(8, 4, 8, 8),
                            child: DText(
                              'Select Type',
                              weight: FontWeight.w500,
                              color: theme.colors.mutedForeground,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: DItemList(
                              borderRadius: BorderRadius.circular(14),
                              children:
                                  _unitOptions.map((unit) {
                                    return ValueListenableBuilder<DataUnitType>(
                                      valueListenable: appDataUnit,
                                      builder:
                                          (_, current, _) => DItem(
                                            title: Text(unit.label),
                                            prefix:
                                                current == unit
                                                    ? HugeIcon(
                                                      icon:
                                                          HugeIcons
                                                              .strokeRoundedTick02,
                                                      size: 22,
                                                      color: lCustom.success,
                                                      strokeWidth: 2,
                                                    )
                                                    : SizedBox(
                                                      width: 22,
                                                      height: 22,
                                                    ),
                                            onPressed: () async {
                                              await setDataUnit(unit);
                                              if (ctx2.mounted) {
                                                Navigator.of(ctx2).pop();
                                              }
                                            },
                                          ),
                                    );
                                  }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final lCustom = dinoCustomColors(
      dark: theme.colors.brightness == Brightness.dark,
    );

    return Container(
      color: theme.colors.secondary,
      child: Column(
        children: [
          DHeader(
            nested: true,
            prefix: [
              DButton(
                size: Platform.isMacOS ? DButtonSize.sm : DButtonSize.md,
                variant: DButtonVariant.ghost,
                onPressed: () => Navigator.of(context).pop(),
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedArrowLeft01,
                  size: Platform.isMacOS ? 20 : 24,
                ),
              ),
            ],
            title: 'Settings',
          ),
          Expanded(
            child: ListView(
              children: [
                Padding(
                  padding: EdgeInsetsGeometry.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Column(
                    spacing: 20,
                    children: [
                      // General
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 8,
                        children: [
                          Padding(
                            padding: EdgeInsetsGeometry.symmetric(
                              horizontal: 12,
                            ),
                            child: DText(
                              'General',
                              weight: FontWeight.w500,
                              color: theme.colors.mutedForeground,
                            ),
                          ),
                          DItemList(
                            borderRadius: BorderRadius.circular(14),
                            children: [
                              // Device name
                              DItem(
                                title: DText('Device Name'),
                                suffix: SizedBox(
                                  width: 160,
                                  child: FTextField(
                                    control: FTextFieldControl.managed(
                                      controller: _nameController,
                                    ),
                                    hint: 'Dino Device',
                                    textAlign: TextAlign.end,
                                    maxLength: 32,
                                    style: FTextFieldStyleDelta.delta(
                                      color: FVariantsValueDelta.delta([
                                        FVariantValueDeltaOperation.all(
                                          Colors.transparent,
                                        ),
                                      ]),
                                      border: FVariantsValueDelta.delta([
                                        FVariantValueDeltaOperation.all(
                                          InputBorder.none,
                                        ),
                                      ]),
                                      contentPadding:
                                          EdgeInsetsGeometryDelta.value(
                                            EdgeInsets.zero,
                                          ),
                                      contentTextStyle: FVariantsDelta.delta([
                                        FVariantOperation.all(
                                          TextStyleDelta.delta(
                                            letterSpacing: -0.09,
                                            fontSize: isDesktop() ? 12 : 14,
                                            color: theme.colors.mutedForeground,
                                          ),
                                        ),
                                      ]),
                                      hintTextStyle: FVariantsDelta.delta([
                                        FVariantOperation.all(
                                          TextStyleDelta.delta(
                                            letterSpacing: -0.09,
                                            fontSize: isDesktop() ? 12 : 14,
                                            color: theme.colors.mutedForeground
                                                .withValues(alpha: 0.5),
                                          ),
                                        ),
                                      ]),
                                    ),
                                    onSubmit: (val) => setDeviceName(val),
                                    onEditingComplete:
                                        () =>
                                            setDeviceName(_nameController.text),
                                  ),
                                ),
                              ),
                              // Receive folder
                              ValueListenableBuilder<String?>(
                                valueListenable: appReceivePath,
                                builder:
                                    (_, path, _) => DItem(
                                      title: Text('Receive Folder'),
                                      description: Text(
                                        path ?? 'Downloads/Dino',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      suffix: HugeIcon(
                                        icon:
                                            HugeIcons.strokeRoundedArrowRight01,
                                        size: 16,
                                        color: theme.colors.foreground,
                                      ),
                                      onPressed: _pickReceiveFolder,
                                    ),
                              ),
                              // Data unit type
                              ValueListenableBuilder<DataUnitType>(
                                valueListenable: appDataUnit,
                                builder:
                                    (_, unit, _) => DItem(
                                      title: Text('Data Unit Type'),
                                      suffix: Row(
                                        spacing: 6,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          DText(
                                            unit.label,
                                            size: DTextSize.sm,
                                            color: theme.colors.mutedForeground,
                                          ),
                                          HugeIcon(
                                            icon:
                                                HugeIcons
                                                    .strokeRoundedArrowDown01,
                                            size: 16,
                                            color: theme.colors.mutedForeground,
                                          ),
                                        ],
                                      ),
                                      onPressed: _showUnitPicker,
                                    ),
                              ),
                              // Language (skipped — placeholder)
                              // DItem(
                              //   title: Text('Language'),
                              //   suffix: Row(
                              //     spacing: 6,
                              //     mainAxisAlignment: MainAxisAlignment.center,
                              //     children: [
                              //       Text(
                              //         'English',
                              //         style: TextStyle(
                              //           fontSize: 14,
                              //           color: theme.colors.mutedForeground,
                              //         ),
                              //       ),
                              //       HugeIcon(
                              //         icon: HugeIcons.strokeRoundedArrowDown01,
                              //         size: 16,
                              //         color: theme.colors.mutedForeground,
                              //       ),
                              //     ],
                              //   ),
                              // ),
                            ],
                          ),
                        ],
                      ),
                      // Theme
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 8,
                        children: [
                          Padding(
                            padding: EdgeInsetsGeometry.symmetric(
                              horizontal: 12,
                            ),
                            child: DText(
                              'Theme',
                              weight: FontWeight.w500,
                              color: theme.colors.mutedForeground,
                            ),
                          ),
                          LThemeSwitcher(),
                        ],
                      ),
                      // Advanced
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 8,
                        children: [
                          Padding(
                            padding: EdgeInsetsGeometry.symmetric(
                              horizontal: 12,
                            ),
                            child: DText(
                              'Advanced',
                              weight: FontWeight.w500,
                              color: theme.colors.mutedForeground,
                            ),
                          ),
                          DItemList(
                            borderRadius: BorderRadius.circular(14),
                            children: [
                              ValueListenableBuilder<bool>(
                                valueListenable: appAlwaysReceive,
                                builder:
                                    (_, val, _) => DItem(
                                      title: Text('Always Receive'),
                                      suffix: DSwitch(
                                        on: val,
                                        onPressed: () => setAlwaysReceive(!val),
                                        variant: DSwitchVariant.success,
                                      ),
                                    ),
                              ),
                              ValueListenableBuilder<bool>(
                                valueListenable: appFullPowerMode,
                                builder:
                                    (_, val, _) => DItem(
                                      title: Text('Full Power Mode'),
                                      suffix: DSwitch(
                                        on: val,
                                        onPressed: () => setFullPowerMode(!val),
                                        variant: DSwitchVariant.success,
                                      ),
                                    ),
                              ),
                              ValueListenableBuilder<bool>(
                                valueListenable: appNotificationsEnabled,
                                builder:
                                    (_, val, _) => DItem(
                                      title: Text('Notifications'),
                                      suffix: DSwitch(
                                        on: val,
                                        onPressed:
                                            () => setNotificationsEnabled(!val),
                                        variant: DSwitchVariant.success,
                                      ),
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      // About
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 8,
                        children: [
                          DItemList(
                            borderRadius: BorderRadius.circular(14),
                            children: [
                              DItem(
                                title: Text('About'),
                                suffix: HugeIcon(
                                  icon: HugeIcons.strokeRoundedArrowRight01,
                                  size: 16,
                                  color: theme.colors.foreground,
                                ),
                              ),
                              DItem(
                                title: Text('Help'),
                                suffix: HugeIcon(
                                  icon: HugeIcons.strokeRoundedArrowRight01,
                                  size: 16,
                                  color: theme.colors.foreground,
                                ),
                              ),
                              DItem(
                                title: Text('Privacy Policy'),
                                suffix: HugeIcon(
                                  icon: HugeIcons.strokeRoundedArrowRight01,
                                  size: 16,
                                  color: theme.colors.foreground,
                                ),
                              ),
                              DItem(
                                padding: EdgeInsets.fromLTRB(16, 8, 10, 8),
                                title: Text('Support Dino'),
                                suffix: DButton(
                                  size: DButtonSize.xs,
                                  variant: DButtonVariant.success,
                                  onPressed: () {
                                    _openSponsorLink(
                                      "https://buymeacoffee.com/kartic",
                                    );
                                  },
                                  child: Text('Donate'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsetsDirectional.symmetric(vertical: 48),
                  child: Column(
                    spacing: 16,
                    children: [
                      DText(
                        'Love this project ?\nBecome a GitHub Sponsor.',
                        color: theme.colors.mutedForeground,
                        textAlign: TextAlign.center,
                      ),
                      DButton(
                        onPressed: () {
                          _openSponsorLink(
                            "https://github.com/sponsors/karticme",
                          );
                        },
                        size: DButtonSize.xs,
                        prefix: HugeIcon(
                          icon: HugeIcons.strokeRoundedFavourite,
                          color: Color(0xFFDB61A2),
                          size: 18,
                        ),
                        style: DButtonStyle(
                          width: 102,
                          gradient: LinearGradient(
                            colors: [
                              theme.colors.foreground,
                              theme.colors.foreground,
                            ],
                          ),
                          textColor: theme.colors.background,
                          boxShadow: [
                            BoxShadow(
                              color: theme.colors.foreground.withValues(
                                alpha: 0.24,
                              ),
                              offset: const Offset(1, 2),
                              blurRadius: 4,
                            ),
                            BoxShadow(
                              color: theme.colors.foreground.withValues(
                                alpha: 1,
                              ),
                              offset: Offset.zero,
                              blurRadius: 0,
                              spreadRadius: 1,
                            ),
                          ],
                          borderColor: theme.colors.foreground,
                        ),
                        child: Text('Sponsor'),
                      ),
                      Padding(
                        padding: EdgeInsetsGeometry.directional(top: 32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Row(
                              spacing: 6,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                DText(
                                  'Made with',
                                  size: DTextSize.h2,
                                  color: theme.colors.mutedForeground,
                                ),
                                SvgPicture.string(
                                  redHeart,
                                  width: 20,
                                  height: 20,
                                ),
                              ],
                            ),
                            Row(
                              spacing: 6,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                DText(
                                  'by',
                                  size: DTextSize.h2,
                                  color: theme.colors.mutedForeground,
                                ),
                                MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                    onTap: () {
                                      _openSponsorLink(
                                        "https://x.com/karticme",
                                      );
                                    },
                                    child: DText(
                                      '@kartic',
                                      size: DTextSize.h2,
                                      color: lCustom.info,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Padding(
                              padding: EdgeInsetsGeometry.only(top: 20),
                              child: DText(
                                "v1.0.0",
                                size: DTextSize.sm,
                                color: theme.colors.mutedForeground,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
