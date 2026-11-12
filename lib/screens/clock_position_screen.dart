import 'package:flutter/material.dart';

import '../core/core.dart';
import '../models/wallpaper_config.dart';
import '../models/wallpaper_data.dart';
import '../widgets/position_editor_scaffold.dart';

class ClockPositionScreen extends StatefulWidget {
  final WallpaperData data;
  final WallpaperConfig config;
  final ValueChanged<WallpaperConfig> onConfigChanged;

  const ClockPositionScreen({
    super.key,
    required this.data,
    required this.config,
    required this.onConfigChanged,
  });

  @override
  State<ClockPositionScreen> createState() => _ClockPositionScreenState();
}

class _ClockPositionScreenState extends State<ClockPositionScreen> {
  static const List<double> _hPresets = [0.25, 0.50, 0.75];
  static const List<double> _vPresets = [0.10, 0.42, 0.75];

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
      title: AppStrings.positionPickerTitle,
      data: widget.data,
      config: _config,
      horizontalPos: _config.horizontalPos,
      verticalPos: _config.verticalPos,
      presetHValues: _hPresets,
      presetVValues: _vPresets,
      scaleValue: _config.fontSize,
      scaleMin: 0.10,
      scaleMax: 1.50,
      scaleLabelText: '${(_config.fontSize * 100).toInt()}%',
      onMoveBy: (dx, dy) {
        _update(_config.copyWith(
          horizontalPos: (_config.horizontalPos + dx).clamp(0.0, 1.0),
          verticalPos: (_config.verticalPos + dy).clamp(0.0, 1.0),
        ));
      },
      onSelectPreset: (col, row) {
        _update(_config.copyWith(
          horizontalPos: _hPresets[col],
          verticalPos: _vPresets[row],
        ));
      },
      onResetCenter: () {
        _update(_config.copyWith(
          horizontalPos: 0.50,
          verticalPos: 0.22,
        ));
      },
      onScaleChanged: (v) {
        _update(_config.copyWith(fontSize: v));
      },
      onConfirm: () {
        widget.onConfigChanged(_config);
        Navigator.of(context).pop();
      },
    );
  }
}