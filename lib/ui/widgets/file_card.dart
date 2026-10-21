import 'dart:io';

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../controller.dart';
import 'app_icon.dart';

/// Miniatura + nome + `duração · tamanho` (Tela 1 com arquivo e Tela 3).
class FileCard extends StatelessWidget {
  const FileCard({
    super.key,
    required this.controller,
    this.withLanguage = false,
  });

  final AppController controller;
  final bool withLanguage;

  @override
  Widget build(BuildContext context) {
    final v = controller.video;
    if (v == null) return const SizedBox.shrink();
    final thumb = v.thumbnailPath;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        spacing: 14,
        children: [
          Container(
            width: 76,
            height: 52,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppColors.track,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: thumb != null
                ? Image.file(
                    File(thumb),
                    width: 76,
                    height: 52,
                    fit: BoxFit.cover,
                    excludeFromSemantics: true,
                  )
                : const AppIcon(
                    AppIcons.video,
                    size: 22,
                    color: AppColors.textMuted,
                  ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 4,
              children: [
                Text(
                  v.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.ui(14.5, 600),
                ),
                Text(
                  controller.videoMeta(withLanguage: withLanguage),
                  style: AppText.mono(12, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
