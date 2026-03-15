import 'package:flutter/material.dart';
import '../models/music_source.dart';

class QualityBadge extends StatelessWidget {
  final String? qualityCode;
  final MusicSource? source;
  final int? bitDepth;
  final int? sampleRate;
  final String? codec;
  final double fontSize;

  const QualityBadge({
    super.key,
    this.qualityCode,
    this.source,
    this.bitDepth,
    this.sampleRate,
    this.codec,
    this.fontSize = 10,
  });

  @override
  Widget build(BuildContext context) {
    if (qualityCode == null || qualityCode!.isEmpty) {
      return const SizedBox.shrink();
    }

    final config = _getBadgeConfig();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: config.backgroundColor,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: config.borderColor, width: 0.7),
      ),
      child: Text(
        config.label,
        style: TextStyle(
          color: config.textColor,
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.45,
        ),
      ),
    );
  }

  _BadgeConfig _getBadgeConfig() {
    final quality = qualityCode ?? '';

    if (quality == 'LOW') {
      return const _BadgeConfig(
        label: 'LOW',
        backgroundColor: Color(0xFF232323),
        textColor: Colors.white,
        borderColor: Color(0xFF343434),
      );
    }

    if (quality == 'OFFLINE') {
      return _BadgeConfig(
        label: _losslessLabel(bitDepth ?? 16, sampleRate ?? 44100),
        backgroundColor: const Color(0xFF202020),
        textColor: Colors.white,
        borderColor: const Color(0xFF4A4A4A),
      );
    }

    if (quality == 'HI_RES_LOSSLESS' || quality == 'MAX') {
      return _BadgeConfig(
        label: _hiResLabel(bitDepth ?? 24, sampleRate ?? 96000),
        backgroundColor: const Color(0xFFB38A2A),
        textColor: const Color(0xFF18130A),
        borderColor: const Color(0xFFD2B165),
      );
    }

    if (quality == 'LOSSLESS' || quality == 'HIGH') {
      return _BadgeConfig(
        label: _losslessLabel(bitDepth ?? 16, sampleRate ?? 44100),
        backgroundColor: const Color(0xFFD8D8D8),
        textColor: const Color(0xFF141414),
        borderColor: const Color(0xFFF1F1F1),
      );
    }

    final fallbackLabel = codec == 'FLAC' || source == MusicSource.subsonic
        ? _losslessLabel(bitDepth ?? 16, sampleRate ?? 44100)
        : quality;

    return _BadgeConfig(
      label: fallbackLabel,
      backgroundColor: const Color(0xFF242424),
      textColor: Colors.white,
      borderColor: const Color(0xFF303030),
    );
  }

  String _losslessLabel(int bitDepth, int hz) {
    return '${bitDepth.toString()}-BIT ${_formatKhz(hz)} KHZ';
  }

  String _hiResLabel(int bitDepth, int hz) {
    return '${bitDepth.toString()}-BIT ${_formatKhz(hz)} KHZ FLAC';
  }

  String _formatKhz(int hz) {
    final khz = hz / 1000;
    if (khz == khz.roundToDouble()) {
      return khz.toStringAsFixed(0);
    }
    return khz.toStringAsFixed(1);
  }
}

class _BadgeConfig {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final Color borderColor;

  const _BadgeConfig({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    required this.borderColor,
  });
}
