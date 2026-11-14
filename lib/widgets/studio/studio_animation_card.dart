import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/core.dart';
import '../../models/depth_scene_config.dart';
import 'studio_common_widgets.dart';

class StudioAnimationCard extends StatelessWidget {
  final DepthSceneConfig config;
  final bool isEnabled;
  final ValueChanged<DepthSceneConfig> onConfigChanged;
  final ValueChanged<bool>? onTriggerPreviewAnimation;

  const StudioAnimationCard({
    super.key,
    required this.config,
    required this.isEnabled,
    required this.onConfigChanged,
    this.onTriggerPreviewAnimation,
  });

  @override
  Widget build(BuildContext context) {
    final List animStyles = [
    {
    'id': 'None',
    'label': AppStrings.animNone,
    'icon': CupertinoIcons.nosign,
    },
    {
    'id': 'Fade',
    'label': AppStrings.animFade,
    'icon': CupertinoIcons.sparkles,
    },
    {
    'id': 'SlideUp',
    'label': AppStrings.animSlideUp,
    'icon': CupertinoIcons.arrow_up_circle,
    },
    {
    'id': 'SlideDown',
    'label': AppStrings.animSlideDown,
    'icon': CupertinoIcons.arrow_down_circle,
    },
    {
    'id': 'ScaleUp',
    'label': AppStrings.animScaleUp,
    'icon': CupertinoIcons.fullscreen,
    },
    {
    'id': 'ScaleDown',
    'label': AppStrings.animScaleDown,
    'icon': CupertinoIcons.fullscreen_exit,
    },
    ];

    return IosSectionCard(
    header: AppStrings.secAnimStyle,
    child: Column(
    children: [
    GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 3,
    crossAxisSpacing: 8,
    mainAxisSpacing: 8,
    mainAxisExtent:
    (54.0 * MediaQuery.textScalerOf(context).scale(1.0))
        .clamp(54.0, 72.0),
    ),
    itemCount: animStyles.length,
    itemBuilder: (context, index) {
    final item = animStyles[index];
    final String id = item['id']! as String;
    final bool isSelected = config.clockAnimStyle == id;

    return PressScaleWrapper(
    child: GestureDetector(
    onTap: isEnabled
    ? () {
    HapticFeedback.selectionClick();
    onConfigChanged(
    config.copyWith(clockAnimStyle: id),
    );
    if (id != 'None') {
    onTriggerPreviewAnimation?.call(true);
    }
    }
        : null,
    child: AnimatedContainer(
    duration: const Duration(milliseconds: 180),
    padding: const EdgeInsets.symmetric(
    horizontal: 6,
    vertical: 6,
    ),
    decoration: BoxDecoration(
    color: isSelected
    ? AppColors.accent.withValues(alpha: 0.22)
        : AppColors.secondarySurface.withValues(alpha: 0.5),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(
    color:
    isSelected ? AppColors.accent : Colors.transparent,
    width: 1.2,
    ),
    ),
    child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
    Icon(
    item['icon']! as IconData,
    size: 19,
    color: isSelected
    ? AppColors.accent
        : AppColors.textPrimary,
    ),
    const SizedBox(height: 5),
    FittedBox(
    fit: BoxFit.scaleDown,
    child: Text(
    item['label']! as String,
    maxLines: 1,
    style: TextStyle(
    color: isSelected
    ? AppColors.textPrimary
        : AppColors.textSecondary,
    fontSize: 11.5,
    fontWeight: isSelected
    ? FontWeight.w600
        : FontWeight.w500,
    ),
    ),
    ),
    ],
    ),
    ),
    ),
    );
    },
    ),
    AnimatedSize(
    duration: const Duration(milliseconds: 220),
    curve: Curves.fastOutSlowIn,
    child: config.clockAnimStyle != 'None'
    ? Column(
    mainAxisSize: MainAxisSize.min,
    children: [
    const StudioDivider(),
    StudioSliderRow(
    label: AppStrings.animDuration,
    valueText: '${config.clockAnimDuration.toInt()} ms',
    value: config.clockAnimDuration,
    min: 200.0,
    max: 1500.0,
    isEnabled: isEnabled,
    onChanged: (val) => onConfigChanged(
    config.copyWith(clockAnimDuration: val),
    ),
    onReset: () => onConfigChanged(
    config.copyWith(clockAnimDuration: 650.0),
    ),
    ),
    const StudioDivider(),
    StudioToggleRow(
    label: AppStrings.animOnScreenOn,
    value: config.animateOnScreenOn,
    isEnabled: isEnabled,
    onChanged: (val) => onConfigChanged(
    config.copyWith(animateOnScreenOn: val),
    ),
    ),
    const StudioDivider(),
    StudioToggleRow(
    label: AppStrings.animOnUnlock,
    value: config.animateOnUnlock,
    isEnabled: isEnabled,
    onChanged: (val) => onConfigChanged(
    config.copyWith(animateOnUnlock: val),
    ),
    ),
    const SizedBox(height: 14),
    _buildPreviewButtons(),
    ],
    )
        : const SizedBox.shrink(),
    ),
    ],
    ),
    );
  }

  Widget _buildPreviewButtons() {
    return Row(
      children: [
        Expanded(
          child: PressScaleWrapper(
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 10,
              ),
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(12),
              onPressed: isEnabled
                  ? () => onTriggerPreviewAnimation?.call(true)
                  : null,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    CupertinoIcons.play_fill,
                    size: 16,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        AppStrings.btnTestAnimIn,
                        maxLines: 1,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: PressScaleWrapper(
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 10,
              ),
              color: AppColors.isLight
                  ? Colors.black.withValues(alpha: 0.05)
                  : Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              onPressed: isEnabled
                  ? () => onTriggerPreviewAnimation?.call(false)
                  : null,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.eye_slash_fill,
                    size: 16,
                    color: AppColors.textPrimary,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        AppStrings.btnTestAnimOut,
                        maxLines: 1,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}