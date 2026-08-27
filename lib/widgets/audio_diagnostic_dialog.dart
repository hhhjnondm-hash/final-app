import 'package:flutter/material.dart';
import '../services/audio_diagnostic_service.dart';
import '../utils/design_system.dart';

class AudioDiagnosticDialog extends StatefulWidget {
  const AudioDiagnosticDialog({super.key});

  @override
  State<AudioDiagnosticDialog> createState() => _AudioDiagnosticDialogState();
}

class _AudioDiagnosticDialogState extends State<AudioDiagnosticDialog> {
  final AudioDiagnosticService _diagnosticService = AudioDiagnosticService();
  bool _isRunning = false;
  Map<String, dynamic>? _results;
  String _diagnosticMessage = '';

  Future<void> _runDiagnostics() async {
    setState(() {
      _isRunning = true;
      _diagnosticMessage = 'جاري تشخيص النظام الصوتي...';
      _results = null;
    });

    try {
      final results = await _diagnosticService.diagnoseAudioSystem();
      setState(() {
        _results = results;
        _diagnosticMessage = AudioDiagnosticService.getDiagnosticMessage(results);
        _isRunning = false;
      });
    } catch (e) {
      setState(() {
        _diagnosticMessage = 'حدث خطأ أثناء التشخيص: $e';
        _isRunning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: DesignSystem.bgCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignSystem.radiusLarge),
      ),
      title: Row(
        children: [
          Icon(
            Icons.graphic_eq_rounded,
            color: DesignSystem.gold,
            size: 24,
          ),
          const SizedBox(width: 12),
          const Text(
            'تشخيص النظام الصوتي',
            style: TextStyle(
              color: DesignSystem.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isRunning)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(DesignSystem.gold),
                  ),
                ),
              )
            else if (_diagnosticMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: DesignSystem.bgDarkest,
                  borderRadius: BorderRadius.circular(DesignSystem.radiusMedium),
                  border: Border.all(
                    color: DesignSystem.gold.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  _diagnosticMessage,
                  style: const TextStyle(
                    color: DesignSystem.textSecondary,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),
            if (_results != null) ...[
              const SizedBox(height: 16),
              _buildDiagnosticDetails(_results!),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isRunning ? null : _runDiagnostics,
          child: Text(
            'تشغيل التشخيص',
            style: TextStyle(
              color: _isRunning ? DesignSystem.textMuted : DesignSystem.gold,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'إغلاق',
            style: TextStyle(
              color: DesignSystem.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDiagnosticDetails(Map<String, dynamic> results) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DesignSystem.bgDarkest,
        borderRadius: BorderRadius.circular(DesignSystem.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailItem('الاتصال بالإنترنت', results['internet_connection']),
          _buildDetailItem('تهيئة مشغل الصوت', results['audio_player_init']),
          _buildDetailItem('ملف صوتي معروف', results['known_url_test']),
          _buildDetailItem('روابط API القرآن', results['quran_api_test']),
          _buildDetailItem('روابط الإذاعة', results['radio_stream_test']),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, dynamic value) {
    final bool isSuccess = value == true;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isSuccess ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: isSuccess ? DesignSystem.success : DesignSystem.error,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: DesignSystem.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          Text(
            isSuccess ? 'يعمل' : 'لا يعمل',
            style: TextStyle(
              color: isSuccess ? DesignSystem.success : DesignSystem.error,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> show(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => const AudioDiagnosticDialog(),
    );
  }
}