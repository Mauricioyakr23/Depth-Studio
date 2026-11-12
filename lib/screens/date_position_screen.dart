import 'package:flutter/material.dart';

import '../core/core.dart';
import '../models/wallpaper_config.dart';
import '../models/wallpaper_data.dart';
import '../widgets/position_editor_scaffold.dart';

class DatePositionScreen extends StatefulWidget {
  final WallpaperData data;
  final WallpaperConfig config;
  final ValueChanged<WallpaperConfig> onConfigChanged;

  const DatePositionScreen({
    super.key,
    required this.data,
    required this.config,
    required this.onConfigChanged,
  });

  @override
  State<DatePositionScreen> createState() => _DatePositionScreenState();
}

class _DatePositionScreenState extends State<DatePositionScreen> {
  static const List<double> _hPresets = [0.25, 0.50, 0.75];
  static const List<double> _vPresets = [0.05, 0.45, 0.85];

  late WallpaperConfig _config;

  @override
  void initState() {
    super.initState();
    _config = widget.config;
  }

  void _update(WallpaperConfig updated) {
    setState(() => _config = updated);
  }

  @override
  Widget build(BuildContext context) {
    return PositionEditorScaffold(
      title: AppStrings.datePositionPickerTitle,
      data: widget.data,
      config: _config,
      horizontalPos: _config.dateHorizontalPos,
      verticalPos: _config.dateVerticalPos,
      presetHValues: _hPresets,
      presetVValues: _vPresets,
      scaleValue: _config.dateFontSize,
      scaleMin: 0.02,
      scaleMax: 0.12,
      scaleLabelText: '${(_config.dateFontSize * 100).toStringAsFixed(1)}%',
      onMoveBy: (dx, dy) {
        _update(_config.copyWith(
          dateHorizontalPos: (_config.dateHorizontalPos + dx).clamp(0.0, 1.0),
          dateVerticalPos: (_config.dateVerticalPos + dy).clamp(0.02, 0.90),
        ));
      },
      onSelectPreset: (col, row) {
        _update(_config.copyWith(
          dateHorizontalPos: _hPresets[col],
          dateVerticalPos: _vPresets[row],
        ));
      },
      onResetCenter: () {
        _update(_config.copyWith(
          dateHorizontalPos: 0.50,
          dateVerticalPos: 0.14,
        ));
      },
      onScaleChanged: (v) {
        _update(_config.copyWith(dateFontSize: v));
      },
      onConfirm: () {
        widget.onConfigChanged(_config);
        Navigator.of(context).pop();
      },
    );
  }
}