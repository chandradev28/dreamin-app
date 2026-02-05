import 'package:flutter/material.dart';
import '../models/music_source.dart';

/// Quality Badge Widget
/// 
/// Simple FLAC-only quality display:
/// - 24-bit Hi-Res FLAC: MAX (Gold badge)
/// - 16-bit CD Quality FLAC: HIGH (Platinum badge)
class QualityBadge extends StatelessWidget {
  final String? qualityCode;
  final MusicSource? source;
  final double fontSize;
  
  const QualityBadge({
    super.key,
    this.qualityCode,
    this.source,
    this.fontSize = 10,
  });
  
  @override
  Widget build(BuildContext context) {
    // Don't show badge until quality is determined
    if (qualityCode == null || qualityCode!.isEmpty) {
      return const SizedBox.shrink();
    }
    
    final config = _getBadgeConfig();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: config.backgroundColor,
        borderRadius: BorderRadius.circular(4),
        border: config.borderColor != null 
            ? Border.all(color: config.borderColor!, width: 0.5)
            : null,
      ),
      child: Text(
        config.label,
        style: TextStyle(
          color: config.textColor,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
  
  _BadgeConfig _getBadgeConfig() {
    final quality = qualityCode!;
    
    // 24-bit Hi-Res FLAC - Gold MAX badge
    if (quality == 'HI_RES_LOSSLESS' || quality == 'MAX') {
      return _BadgeConfig(
        label: 'MAX',
        backgroundColor: const Color(0xFFFFD700), // Gold
        textColor: const Color(0xFF1A1A1A), // Dark text
        borderColor: const Color(0xFFDAA520), // Darker gold border
      );
    }
    
    // 16-bit CD Quality FLAC - Platinum HIGH badge (default for all FLAC)
    return _BadgeConfig(
      label: 'HIGH',
      backgroundColor: const Color(0xFFE5E4E2), // Platinum
      textColor: const Color(0xFF1A1A1A), // Dark text
      borderColor: const Color(0xFFC0C0C0), // Silver border
    );
  }
}

class _BadgeConfig {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final Color? borderColor;
  
  const _BadgeConfig({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    this.borderColor,
  });
}
