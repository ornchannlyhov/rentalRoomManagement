import 'package:flutter/material.dart';
import 'package:joul_v2/l10n/app_localizations.dart';

/// Small bar above the bottom menu while the app can't reach the server.
/// Says whether the phone is offline or the server isn't answering, and how
/// many changes are waiting to upload.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({
    super.key,
    this.serverDown = false,
    this.waitingCount = 0,
  });

  final bool serverDown;
  final int waitingCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final localizations = AppLocalizations.of(context);
    final textColor = isDark ? Colors.grey.shade300 : Colors.grey.shade700;

    final title = localizations == null
        ? 'Offline mode'
        : serverDown
            ? localizations.bannerServerDown
            : localizations.bannerOffline;
    final detail = localizations != null && waitingCount > 0
        ? localizations.changesWaiting(waitingCount)
        : null;

    return Positioned(
      left: 12,
      right: 12,
      bottom: kBottomNavigationBarHeight + 32,
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(8),
        color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                serverDown
                    ? Icons.cloud_queue_outlined
                    : Icons.cloud_off_outlined,
                size: 16,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  detail == null ? title : '$title · $detail',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
