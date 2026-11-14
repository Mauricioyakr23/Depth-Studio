import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/core.dart';
import '../../liquid_glass.dart';

class IosVisualColorPickerDialog extends StatefulWidget {
  final Color initialColor;
  final List<Color> materialYouPalette;
  final ValueChanged<Color> onColorConfirmed;

  const IosVisualColorPickerDialog({
    super.key,
    required this.initialColor,
    required this.materialYouPalette,
    required this.onColorConfirmed,
  });

  @override
  State<IosVisualColorPickerDialog> createState() =>
      _IosVisualColorPickerDialogState();
}

class _IosVisualColorPickerDialogState
    extends State<IosVisualColorPickerDialog> {
  late HSVColor _hsv;
  late TextEditingController _hexController;

  @override
  void initState() {
    super.initState();
    _hsv = HSVColor.fromColor(widget.initialColor);
    _hexController =
        TextEditingController(text: _colorToHex(widget.initialColor));
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  String _colorToHex(Color c) {
    return c
        .toARGB32()
        .toRadixString(16)
        .padLeft(8, '0')
        .substring(2)
        .toUpperCase();
  }

  void _updateFromHsv(HSVColor updated) {
    setState(() {
      _hsv = updated;
      _hexController.text = _colorToHex(updated.toColor());
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color currentColor = _hsv.toColor();

    return SafeArea(
      child: AnimatedPadding(
        padding: MediaQuery.viewInsetsOf(context) +
            const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutQuad,
        child: Align(
          alignment: Alignment.center,
          child: SingleChildScrollView(
            child: Material(
              color: Colors.transparent,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 340),
                child: LiquidGlass(
                  useOwnLayer: true,
                  borderRadius: 22,
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            AppStrings.colorSpectrum,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.3,
                            ),
                          ),
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              width: AppLayout.minTouchTarget,
                              height: AppLayout.minTouchTarget,
                              alignment: Alignment.centerRight,
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: AppColors.secondarySurface,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  CupertinoIcons.xmark,
                                  size: 14,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _buildSaturationValueBox(currentColor),
                      const SizedBox(height: 14),
                      _buildHueBar(),
                      const SizedBox(height: 16),
                      _buildHexRow(currentColor),
                      const SizedBox(height: 16),
                      Text(
                        AppStrings.materialYouAccents,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildPaletteSwatches(),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: CupertinoButton(
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(12),
                          onPressed: () {
                            widget.onColorConfirmed(currentColor);
                            Navigator.pop(context);
                          },
                          child: Text(
                            AppStrings.applyColor,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14.5,
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
          ),
        ),
      ),
    );
  }

  Widget _buildSaturationValueBox(Color currentColor) {
    return SizedBox(
      height: 175,
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double w = constraints.maxWidth;
          final double h = constraints.maxHeight;

          void handlePan(Offset localPos) {
            final double s = (localPos.dx / w).clamp(0.0, 1.0);
            final double v = (1.0 - (localPos.dy / h)).clamp(0.0, 1.0);
            _updateFromHsv(_hsv.withSaturation(s).withValue(v));
          }

          return GestureDetector(
            onPanDown: (d) => handlePan(d.localPosition),
            onPanUpdate: (d) => handlePan(d.localPosition),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                children: [
                  Container(
                    color: HSVColor.fromAHSV(1.0, _hsv.hue, 1.0, 1.0).toColor(),
                  ),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [Colors.white, Colors.transparent],
                      ),
                    ),
                  ),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black],
                      ),
                    ),
                  ),
                  Positioned(
                    left: (_hsv.saturation * w) - 12,
                    top: ((1.0 - _hsv.value) * h) - 12,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: currentColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 2.5,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black54,
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHueBar() {
    return SizedBox(
      height: 26,
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double w = constraints.maxWidth;
          void handleHue(Offset localPos) {
            final double hue = ((localPos.dx / w).clamp(0.0, 1.0)) * 360.0;
            _updateFromHsv(_hsv.withHue(hue));
          }

          return GestureDetector(
            onPanDown: (d) => handleHue(d.localPosition),
            onPanUpdate: (d) => handleHue(d.localPosition),
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Container(
                  height: 14,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(7),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFFF0000),
                        Color(0xFFFFFF00),
                        Color(0xFF00FF00),
                        Color(0xFF00FFFF),
                        Color(0xFF0000FF),
                        Color(0xFFFF00FF),
                        Color(0xFFFF0000),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: ((_hsv.hue / 360.0) * w).clamp(0.0, w) - 11,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color:
                      HSVColor.fromAHSV(1.0, _hsv.hue, 1.0, 1.0).toColor(),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 2.5,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black45,
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHexRow(Color currentColor) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: currentColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border, width: 1),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'HEX',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: CupertinoTextField(
            controller: _hexController,
            prefix: Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Text(
                '#',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                ),
              ),
            ),
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.1,
            ),
            maxLength: 6,
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 9,
            ),
            decoration: BoxDecoration(
              color: AppColors.secondarySurface,
              borderRadius: BorderRadius.circular(10),
            ),
            onChanged: (val) {
              final clean = val.replaceAll('#', '').trim();
              if (clean.length == 6) {
                final int? parsed = int.tryParse('FF$clean', radix: 16);
                if (parsed != null) {
                  setState(() {
                    _hsv = HSVColor.fromColor(Color(parsed));
                  });
                }
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPaletteSwatches() {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: widget.materialYouPalette.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final c = widget.materialYouPalette[i];
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _updateFromHsv(HSVColor.fromColor(c)),
            child: Center(
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: c,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border, width: 1),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}