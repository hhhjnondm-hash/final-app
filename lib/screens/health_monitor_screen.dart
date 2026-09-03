import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/health_monitor.dart';
import '../utils/design_system.dart';

/// Health monitoring screen for debugging
/// Shows the health status of various app systems
class HealthMonitorScreen extends StatefulWidget {
  const HealthMonitorScreen({super.key});

  @override
  State<HealthMonitorScreen> createState() => _HealthMonitorScreenState();
}

class _HealthMonitorScreenState extends State<HealthMonitorScreen> {
  final HealthMonitor _healthMonitor = HealthMonitor();
  HealthReport? _currentReport;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadHealthReport();
  }

  Future<void> _loadHealthReport() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final report = await _healthMonitor.performHealthCheck();
      setState(() {
        _currentReport = report;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading health report: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مراقبة صحة النظام'),
        backgroundColor: DesignSystem.bgDark,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadHealthReport,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentReport == null
              ? _buildErrorView()
              : _buildHealthView(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          const Text('فشل تحميل تقرير الصحة'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadHealthReport,
            child: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOverallHealthCard(),
          const SizedBox(height: 16),
          _buildSystemChecksList(),
          const SizedBox(height: 16),
          _buildDetailsSection(),
        ],
      ),
    );
  }

  Widget _buildOverallHealthCard() {
    final report = _currentReport!;
    final status = report.overallHealth;
    final statusColor = _getStatusColor(status);
    final statusText = _getStatusText(status);

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getStatusIcon(status),
                  color: statusColor,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الحالة العامة',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        statusText,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('صحي', report.healthyChecks, Colors.green),
                _buildStatItem('تحذير', report.degradedChecks, Colors.orange),
                _buildStatItem('فاشل', report.unhealthyChecks, Colors.red),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'آخر فحص: ${_formatDateTime(report.checkedAt)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          '$value',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildSystemChecksList() {
    final report = _currentReport!;
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'فحوصات النظام',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ...report.checks.entries.map((entry) {
              return _buildCheckItem(entry.key, entry.value);
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckItem(String name, HealthCheckResult result) {
    final statusColor = _getStatusColor(result.status);
    final statusText = _getStatusText(result.status);

    return ListTile(
      leading: Icon(
        _getStatusIcon(result.status),
        color: statusColor,
      ),
      title: Text(result.name),
      subtitle: Text(result.message),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          statusText,
          style: TextStyle(
            color: statusColor,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
      onTap: () => _showCheckDetails(result),
    );
  }

  Widget _buildDetailsSection() {
    final report = _currentReport!;
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'تفاصيل إضافية',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Text(
              'إجمالي الفحوصات: ${report.totalChecks}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              'نسبة الفحوصات الصحية: ${((report.healthyChecks / report.totalChecks) * 100).toStringAsFixed(1)}%',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  void _showCheckDetails(HealthCheckResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(result.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('الحالة', _getStatusText(result.status)),
              _buildDetailRow('الرسالة', result.message),
              const SizedBox(height: 16),
              Text(
                'التفاصيل:',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Text(
                result.details.toString(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                    ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(HealthStatus status) {
    switch (status) {
      case HealthStatus.healthy:
        return Colors.green;
      case HealthStatus.degraded:
        return Colors.orange;
      case HealthStatus.unhealthy:
        return Colors.red;
      case HealthStatus.unknown:
        return Colors.grey;
    }
  }

  String _getStatusText(HealthStatus status) {
    switch (status) {
      case HealthStatus.healthy:
        return 'صحي';
      case HealthStatus.degraded:
        return 'تحذير';
      case HealthStatus.unhealthy:
        return 'فاشل';
      case HealthStatus.unknown:
        return 'غير معروف';
    }
  }

  IconData _getStatusIcon(HealthStatus status) {
    switch (status) {
      case HealthStatus.healthy:
        return Icons.check_circle;
      case HealthStatus.degraded:
        return Icons.warning;
      case HealthStatus.unhealthy:
        return Icons.error;
      case HealthStatus.unknown:
        return Icons.help;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
