import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/core.dart';
import 'liquid_glass.dart';

Future<String?> showRenameProjectDialog({
  required BuildContext context,
  required String currentName,
}) async {
  final TextEditingController textController = TextEditingController(
    text: currentName,
  )..selection = TextSelection(
    baseOffset: 0,
    extentOffset: currentName.length,
  );

  try {
    return await showGeneralDialog<String>(
      context: context,
      barrierDismissible: true,
      barrierLabel: AppStrings.cancel,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (dialogCtx, animation, secondaryAnimation) {
        return SafeArea(
          child: AnimatedPadding(
            padding: MediaQuery.viewInsetsOf(dialogCtx) +
                const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutQuad,
            child: Align(
              alignment: Alignment.center,
              child: Material(
                color: Colors.transparent,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 340),
                  child: LiquidGlass(
                    useOwnLayer: true,
                    borderRadius: 22,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          AppStrings.renameWallpaperTitle,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 14),
                        CupertinoTextField(
                          controller: textController,
                          autofocus: true,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (val) {
                            final trimmed = val.trim();
                            if (trimmed.isNotEmpty && trimmed != currentName) {
                              HapticFeedback.selectionClick();
                              Navigator.of(dialogCtx).pop(trimmed);
                            } else {
                              Navigator.of(dialogCtx).pop();
                            }
                          },
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                          ),
                          placeholderStyle: TextStyle(
                            color: AppColors.textDisabled,
                            fontSize: 15,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.secondarySurface
                                .withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.border,
                              width: 0.6,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            CupertinoButton(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              onPressed: () => Navigator.of(dialogCtx).pop(),
                              child: Text(
                                AppStrings.cancel,
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            CupertinoButton(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(12),
                              onPressed: () {
                                final trimmed = textController.text.trim();
                                if (trimmed.isNotEmpty &&
                                    trimmed != currentName) {
                                  HapticFeedback.selectionClick();
                                  Navigator.of(dialogCtx).pop(trimmed);
                                } else {
                                  Navigator.of(dialogCtx).pop();
                                }
                              },
                              child: Text(
                                AppStrings.apply,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
  } finally {
    textController.dispose();
  }
}