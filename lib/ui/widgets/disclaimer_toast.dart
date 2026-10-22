import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import 'app_icon.dart';
import 'common.dart';

const disclaimerTitle = 'Feito para aprender e testar';
const disclaimerText =
    'Esta aplicação é um projeto de estudo, sem fins comerciais. '
    'Podem ocorrer erros na execução: use por sua conta e risco.';

/// Aviso de uso que aparece ao abrir o app e só fecha no X.
class DisclaimerToast extends StatelessWidget {
  const DisclaimerToast({super.key, required this.onClose});
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final pal = context.palette;
    return Semantics(
      container: true,
      liveRegion: true,
      label: 'Aviso: $disclaimerTitle. $disclaimerText',
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.borderStrong),
          boxShadow: const [
            BoxShadow(
              color: Color(0x73140E1A),
              blurRadius: 40,
              offset: Offset(0, 16),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Filete salmão à esquerda.
              Container(width: 3, color: pal.accent),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 6, 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 14,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: pal.accentChipBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: AppIcon(
                          AppIcons.alert,
                          size: 18,
                          strokeWidth: 2,
                          color: pal.accentSoftText,
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 4,
                          children: [
                            Text(
                              'AVISO',
                              style: AppText.ui(
                                11,
                                600,
                                color: pal.accentSoftText,
                                letterSpacingEm: 0.1,
                              ),
                            ),
                            Text(
                              disclaimerTitle,
                              style: AppText.display(
                                16,
                                700,
                                letterSpacingEm: -0.01,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              disclaimerText,
                              style: AppText.ui(
                                13,
                                400,
                                color: AppColors.textMuted,
                                height: 1.55,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Pressable(
                        onTap: onClose,
                        radius: 10,
                        semanticLabel: 'Fechar aviso',
                        tooltip: 'Fechar aviso',
                        builder: (context, hovered, _) => AnimatedContainer(
                          duration: motion(context),
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: hovered
                                ? AppColors.surfaceHoverRow
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: AppIcon(
                            AppIcons.close,
                            size: 16,
                            strokeWidth: 2,
                            color: hovered
                                ? AppColors.text
                                : AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
