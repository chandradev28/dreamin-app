import 'package:flutter/material.dart';
import '../models/music_source.dart';

/// Quality Badge Widget
/// 
/// Displays audio quality with service-specific styling:
/// - Qobuz MAX (HI_RES_LOSSLESS): Gold badge
/// - Qobuz/Tidal HIGH (LOSSLESS): Platinum/Silver badge
/// - Default: Subtle white badge
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
    final quality = qualityCode ?? 'HIGH';
    final isQobuz = source == MusicSource.qobuz;
    
    // Qobuz MAX (24-bit Hi-Res) - Gold
    if (quality == 'HI_RES_LOSSLESS' && isQobuz) {
      return _BadgeConfig(
        label: 'MAX',
        backgroundColor: const Color(0xFFFFD700), // Gold
        textColor: const Color(0xFF1A1A1A), // Dark text
        borderColor: const Color(0xFFDAA520), // Darker gold border
      );
    }
    
    // Qobuz HIGH or Tidal LOSSLESS - Platinum
    if (quality == 'LOSSLESS' || (quality == 'HI_RES_LOSSLESS' && !isQobuz)) {
      return _BadgeConfig(
        label: 'HIGH',
        backgroundColor: const Color(0xFFE5E4E2), // Platinum
        textColor: const Color(0xFF1A1A1A), // Dark text
        borderColor: const Color(0xFFC0C0C0), // Silver border
      );
    }
    
    // Tidal HI_RES_LOSSLESS (Master) - Platinum
    if (quality == 'HI_RES_LOSSLESS') {
      return _BadgeConfig(
        label: 'MAX',
        backgroundColor: const Color(0xFFE5E4E2), // Platinum
        textColor: const Color(0xFF1A1A1A),
        borderColor: const Color(0xFFC0C0C0),
      );
    }
    
    // Default HIGH - Subtle
    return _BadgeConfig(
      label: _getLabel(quality),
      backgroundColor: Colors.white.withOpacity(0.2),
      textColor: Colors.white,
    );
  }
  
  String _getLabel(String quality) {
    switch (quality) {
      case 'HI_RES_LOSSLESS': return 'MAX';
      case 'LOSSLESS': return 'HIGH';
      case 'HIGH': return 'AAC';
      case 'LOW': return 'LOW';
      default: return 'HIGH';
    }
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
