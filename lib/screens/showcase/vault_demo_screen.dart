import 'package:app_adaptive_widgets/app_adaptive_widgets.dart';
import 'package:app_secure_storage/app_secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app_template/destination.dart';
import 'package:flutter_app_template/screens/showcase/showcase_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class VaultDemoScreen extends StatefulWidget {
  static const name = 'Vault Demo';
  static const path = 'vault';

  const VaultDemoScreen({super.key});

  @override
  State<VaultDemoScreen> createState() => _VaultDemoScreenState();
}

class _VaultDemoScreenState extends State<VaultDemoScreen> {
  final _keyController = TextEditingController();
  final _valueController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  Map<String, String> _storedSecrets = {};
  bool _isLoading = false;
  String? _lastResult;
  bool _lastResultSuccess = true;

  @override
  void initState() {
    super.initState();
    _loadAllSecrets();
  }

  @override
  void dispose() {
    _keyController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  VaultRepository get _vault => context.read<VaultRepository>();

  Future<void> _loadAllSecrets() async {
    setState(() => _isLoading = true);
    try {
      final secrets = await _vault.readAll();
      setState(() {
        _storedSecrets = secrets;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _lastResult = 'Error loading secrets: $e';
        _lastResultSuccess = false;
      });
    }
  }

  Future<void> _writeSecret() async {
    if (!_formKey.currentState!.validate()) return;

    final key = _keyController.text.trim();
    final value = _valueController.text;

    setState(() => _isLoading = true);
    try {
      await _vault.write(key: key, value: value);
      await _loadAllSecrets();
      setState(() {
        _lastResult = 'Saved "$key" successfully';
        _lastResultSuccess = true;
      });
      _valueController.clear();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _lastResult = 'Error saving: $e';
        _lastResultSuccess = false;
      });
    }
  }

  Future<void> _readSecret(String key) async {
    setState(() => _isLoading = true);
    try {
      final value = await _vault.read(key: key);
      setState(() {
        _isLoading = false;
        if (value != null) {
          _lastResult = 'Value for "$key": $value';
          _lastResultSuccess = true;
        } else {
          _lastResult = 'No value found for "$key"';
          _lastResultSuccess = false;
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _lastResult = 'Error reading: $e';
        _lastResultSuccess = false;
      });
    }
  }

  Future<void> _deleteSecret(String key) async {
    setState(() => _isLoading = true);
    try {
      await _vault.delete(key: key);
      await _loadAllSecrets();
      setState(() {
        _lastResult = 'Deleted "$key" successfully';
        _lastResultSuccess = true;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _lastResult = 'Error deleting: $e';
        _lastResultSuccess = false;
      });
    }
  }

  Future<void> _deleteAllSecrets() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Secrets?'),
        content: const Text(
          'This will permanently delete all stored secrets. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      await _vault.deleteAll();
      await _loadAllSecrets();
      setState(() {
        _lastResult = 'All secrets deleted';
        _lastResultSuccess = true;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _lastResult = 'Error deleting all: $e';
        _lastResultSuccess = false;
      });
    }
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
                title: const Text(VaultDemoScreen.name),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _isLoading ? null : _loadAllSecrets,
                    tooltip: 'Refresh',
                  ),
                  if (_storedSecrets.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.delete_sweep),
                      onPressed: _isLoading ? null : _deleteAllSecrets,
                      tooltip: 'Delete All',
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoCard(context),
        const SizedBox(height: 16),
        _buildInputCard(context),
        const SizedBox(height: 16),
        if (_lastResult != null) ...[
          _buildResultCard(context),
          const SizedBox(height: 16),
        ],
        _buildStoredSecretsCard(context),
      ],
    );
  }

  Widget _buildInfoCard(BuildContext context) {
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
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.info_outline, color: Colors.amber, size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  'About Vault',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'The Vault package provides secure storage for sensitive data using '
              'platform-native mechanisms:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            _buildPlatformRow(context, 'iOS/macOS', 'Keychain Services'),
            _buildPlatformRow(context, 'Android', 'EncryptedSharedPreferences'),
            _buildPlatformRow(context, 'Linux', 'libsecret'),
            _buildPlatformRow(context, 'Windows', 'Credential Manager'),
          ],
        ),
      ),
    );
  }

  Widget _buildPlatformRow(BuildContext context, String platform, String storage) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          const SizedBox(width: 8),
          Icon(
            Icons.check_circle,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            '$platform: ',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(
            storage,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildInputCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.add_circle, color: Colors.blue, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Store Secret',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _keyController,
                decoration: const InputDecoration(
                  labelText: 'Key',
                  hintText: 'e.g., api_token',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.key),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a key';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _valueController,
                decoration: const InputDecoration(
                  labelText: 'Value',
                  hintText: 'Secret value to store',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a value';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isLoading ? null : _writeSecret,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: const Text('Save Secret'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard(BuildContext context) {
    return Card(
      color: _lastResultSuccess
          ? Theme.of(context).colorScheme.primaryContainer
          : Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              _lastResultSuccess ? Icons.check_circle : Icons.error,
              color: _lastResultSuccess
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _lastResult!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: _lastResultSuccess
                          ? Theme.of(context).colorScheme.onPrimaryContainer
                          : Theme.of(context).colorScheme.onErrorContainer,
                    ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => setState(() => _lastResult = null),
              iconSize: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoredSecretsCard(BuildContext context) {
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
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.folder_special, color: Colors.green, size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  'Stored Secrets',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                Text(
                  '${_storedSecrets.length} items',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_storedSecrets.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.lock_open,
                        size: 48,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No secrets stored',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _storedSecrets.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final entry = _storedSecrets.entries.elementAt(index);
                  return _buildSecretTile(context, entry.key, entry.value);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecretTile(BuildContext context, String key, String value) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.vpn_key, size: 20),
      ),
      title: Text(
        key,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              fontFamily: 'monospace',
            ),
      ),
      subtitle: Text(
        '\u2022' * value.length.clamp(4, 16),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.visibility),
            onPressed: () => _readSecret(key),
            tooltip: 'View value',
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Copied "$key" to clipboard'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            tooltip: 'Copy value',
          ),
          IconButton(
            icon: Icon(
              Icons.delete,
              color: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => _deleteSecret(key),
            tooltip: 'Delete',
          ),
        ],
      ),
    );
  }
}
