

import 'package:flutter/material.dart';

import '../../../utils/constants/colors.dart';

class InfoBanner extends StatefulWidget {

  final String title;
  final String description;

  const InfoBanner({super.key, required this.title, required this.description});

  @override
  State<InfoBanner> createState() => _InfoBannerState();
}

class _InfoBannerState extends State<InfoBanner> {

  bool showInfo = true;

  @override
  Widget build(BuildContext context) {
    return AnimatedCrossFade(
      duration: const Duration(milliseconds: 250),
      crossFadeState: showInfo ? CrossFadeState.showFirst : CrossFadeState.showSecond,
      firstChild: Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              TColors.primary.withOpacity(0.1),
              TColors.secondary.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: TColors.primary.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info Icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: TColors.primary.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.info_outline,
                size: 20,
                color: TColors.black,
              ),
            ),
            const SizedBox(width: 12),
            // Text Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: TColors.black,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.black54,
                      fontWeight: FontWeight.w400,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Close Button
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => setState(() => showInfo = false),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: TColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  size: 18,
                  color: Colors.black45,
                ),
              ),
            ),
          ],
        ),
      ),
      secondChild: const SizedBox(height: 0),
    );

  }
}
