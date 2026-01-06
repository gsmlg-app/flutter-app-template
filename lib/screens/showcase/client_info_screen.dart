import 'package:app_adaptive_widgets/app_adaptive_widgets.dart';
import 'package:app_client_info/app_client_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app_template/destination.dart';
import 'package:flutter_app_template/screens/showcase/showcase_screen.dart';

class ClientInfoScreen extends StatefulWidget {
  static const name = 'Client Info Demo';
  static const path = 'client-info';

  const ClientInfoScreen({super.key});

  @override
  State<ClientInfoScreen> createState() => _ClientInfoScreenState();
}

class _ClientInfoScreenState extends State<ClientInfoScreen> {
  ClientInfoData? _clientInfo;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadClientInfo();
  }

  Future<void> _loadClientInfo() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await ClientInfo.instance.getData();
      setState(() {
        _clientInfo = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshClientInfo() async {
    await ClientInfo.instance.refresh();
    await _loadClientInfo();
  }

  @override
  Widget build(BuildContext context) {
    return AppAdaptiveScaffold(
      selectedIndex: Destinations.indexOf(
        const Key(ShowcaseScreen.name),
        context,
      ),
      onSelectedIndexChange: (idx) => Destinations.changeHandler(idx, context),
      destinations: Destinations.navs(context),
      body: (context) {
        return SafeArea(
          child: CustomScrollView(
            slivers: <Widget>[
              SliverAppBar(
                title: const Text(ClientInfoScreen.name),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _isLoading ? null : _refreshClientInfo,
                    tooltip: 'Refresh',
                  ),
                ],
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverToBoxAdapter(
                  child: _buildContent(context),
                ),
              ),
            ],
          ),
        );
      },
      smallSecondaryBody: AdaptiveScaffold.emptyBuilder,
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return _buildErrorCard(context);
    }

    if (_clientInfo == null) {
      return const Center(
        child: Text('No client info available'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoCard(
          context,
          title: 'Platform',
          icon: Icons.devices,
          color: Colors.blue,
          children: [
            _buildInfoRow(context, 'Platform', _clientInfo!.platform),
            _buildInfoRow(
              context,
              'Timestamp',
              _formatTimestamp(_clientInfo!.timestamp),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_clientInfo!.additionalData.isNotEmpty) ...[
          _buildInfoCard(
            context,
            title: 'Additional Data',
            icon: Icons.info_outline,
            color: Colors.teal,
            children: _clientInfo!.additionalData.entries.map((entry) {
              return _buildInfoRow(
                context,
                _formatKey(entry.key),
                _formatValue(entry.value),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],
        _buildRawDataCard(context),
      ],
    );
  }

  Widget _buildErrorCard(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load client info',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadClientInfo,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRawDataCard(BuildContext context) {
    final rawData = _clientInfo!.toMap().toString();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.code, color: Colors.grey, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Raw Data',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: rawData));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Copied to clipboard'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  tooltip: 'Copy to clipboard',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                rawData,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')} '
        '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}';
  }

  String _formatKey(String key) {
    // Convert camelCase or snake_case to Title Case
    return key
        .replaceAllMapped(
          RegExp(r'([a-z])([A-Z])'),
          (match) => '${match.group(1)} ${match.group(2)}',
        )
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) =>
            word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : word)
        .join(' ');
  }

  String _formatValue(dynamic value) {
    if (value is Map || value is List) {
      return value.toString();
    }
    return value?.toString() ?? 'N/A';
  }
}
