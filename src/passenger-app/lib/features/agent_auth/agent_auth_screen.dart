import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ride_hermes_passenger/config/theme.dart';
import 'package:ride_hermes_passenger/providers/auth_provider.dart';

class AgentAuthScreen extends ConsumerStatefulWidget {
  const AgentAuthScreen({super.key});

  @override
  ConsumerState<AgentAuthScreen> createState() => _AgentAuthScreenState();
}

class _AgentAuthScreenState extends ConsumerState<AgentAuthScreen> {
  bool _loading = false;
  String? _generatedKey;
  String? _error;
  List<Map<String, dynamic>> _keys = [];

  @override
  void initState() {
    super.initState();
    _loadKeys();
  }

  Future<void> _loadKeys() async {
    final api = ref.read(apiServiceProvider);
    final result = await api.get('/api/v1/passenger/agent/keys');
    if (result.isSuccess && result.data != null) {
      final list = result.data!['data']?['list'] as List<dynamic>? ?? [];
      setState(() {
        _keys = list.cast<Map<String, dynamic>>();
      });
    }
  }

  Future<void> _generateKey(String agentName) async {
    setState(() {
      _loading = true;
      _error = null;
      _generatedKey = null;
    });
    final api = ref.read(apiServiceProvider);
    final result = await api.post('/api/v1/passenger/agent/keys', data: {
      'agent_name': agentName,
    });
    setState(() => _loading = false);

    if (result.isSuccess && result.data != null) {
      final data = result.data!['data'] as Map<String, dynamic>?;
      if (data != null) {
        setState(() => _generatedKey = data['api_key'] as String?);
        _loadKeys();
      }
    } else {
      setState(() => _error = result.message ?? '生成失败');
    }
  }

  Future<void> _revokeKey(int id) async {
    final api = ref.read(apiServiceProvider);
    final result = await api.delete('/api/v1/passenger/agent/keys/$id');
    if (result.isSuccess) {
      _loadKeys();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? '吊销失败')),
      );
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label 已复制到剪贴板')),
    );
  }

  void _exportAll() {
    final user = ref.read(authProvider).user;
    final userId = user?.id.toString() ?? '';
    final text = 'RIDEHERMES_API_KEY=$_generatedKey\nRIDEHERMES_USER_ID=$userId';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('API Key + User ID 已导出到剪贴板')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final userId = user?.id.toString() ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('智能体授权')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User ID card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.base),
                child: Row(
                  children: [
                    const Icon(Icons.person, color: AppColors.primary),
                    const SizedBox(width: AppSpacing.md),
                    const Text('User ID', style: TextStyle(fontWeight: FontWeight.w500)),
                    const Spacer(),
                    Text(userId, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(width: AppSpacing.sm),
                    if (userId.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.copy, size: 18),
                        onPressed: () => _copyToClipboard(userId, 'User ID'),
                        tooltip: '复制',
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Generate section
            const Text('生成 API Key',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              '选择要授权的智能体，生成 API Key 后可复制使用。API Key 仅展示一次，请妥善保管。',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: AppSpacing.base),

            // Agent name buttons
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _agentChip('openclaw', Icons.smart_toy),
                _agentChip('hermes', Icons.hub),
                _agentChip('claude-desktop', Icons.desktop_windows),
                _agentChip('claude-code', Icons.code),
                _agentChip('other', Icons.more_horiz),
              ],
            ),

            // Generated key display
            if (_generatedKey != null) ...[
              const SizedBox(height: AppSpacing.xl),
              Container(
                padding: const EdgeInsets.all(AppSpacing.base),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning_amber, color: AppColors.warning, size: 18),
                        const SizedBox(width: AppSpacing.sm),
                        const Text('请复制并妥善保管',
                            style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.warning)),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const Text('此 Key 仅展示一次，关闭后无法再次查看',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(height: AppSpacing.base),
                    // API Key
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: SelectableText(
                              _generatedKey!,
                              style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy, size: 18),
                            onPressed: () => _copyToClipboard(_generatedKey!, 'API Key'),
                            tooltip: '复制 API Key',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.base),
                    // Export button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.download, size: 18),
                        label: const Text('导出 Key + User ID（复制到剪贴板）'),
                        onPressed: _exportAll,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    // Install command
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1F2937),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'npx ridehermes-mcp-server setup',
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'monospace',
                                fontSize: 13,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy, size: 18, color: Colors.white70),
                            onPressed: () => _copyToClipboard(
                                'npx ridehermes-mcp-server setup', '安装命令'),
                            tooltip: '复制安装命令',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (_error != null) ...[
              const SizedBox(height: AppSpacing.base),
              Text(_error!, style: const TextStyle(color: AppColors.error)),
            ],

            if (_loading)
              const Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: Center(child: CircularProgressIndicator()),
              ),

            // Existing keys list
            const SizedBox(height: AppSpacing.xxl),
            const Text('已授权的智能体',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: AppSpacing.sm),
            if (_keys.isEmpty)
              const Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: Text('暂无已授权的智能体',
                    style: TextStyle(color: AppColors.textHint),
                    textAlign: TextAlign.center),
              )
            else
              ...(_keys.map((k) => _keyTile(k))),
          ],
        ),
      ),
    );
  }

  Widget _agentChip(String name, IconData icon) {
    return ActionChip(
      avatar: Icon(icon, size: 18, color: AppColors.primary),
      label: Text(name),
      onPressed: _loading ? null : () => _generateKey(name),
    );
  }

  Widget _keyTile(Map<String, dynamic> key) {
    final status = key['status'] as int? ?? 0;
    final isActive = status == 1;
    final agentName = key['agent_name'] as String? ?? '';
    final prefix = key['prefix'] as String? ?? '';
    final createdAt = key['created_at'] as String? ?? '';
    final id = key['id'] as int? ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isActive ? AppColors.success.withOpacity(0.1) : AppColors.textHint.withOpacity(0.1),
          child: Icon(Icons.key, color: isActive ? AppColors.success : AppColors.textHint, size: 20),
        ),
        title: Text(agentName, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text('$prefix  $createdAt', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        trailing: isActive
            ? TextButton(
                onPressed: () => _showRevokeDialog(id, agentName),
                child: const Text('吊销', style: TextStyle(color: AppColors.error)),
              )
            : const Chip(
                label: Text('已吊销', style: TextStyle(fontSize: 11)),
                backgroundColor: Colors.transparent,
              ),
      ),
    );
  }

  void _showRevokeDialog(int id, String agentName) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认吊销'),
        content: Text('确定要吊销「$agentName」的 API Key 吗？吊销后该智能体将无法代你叫车。'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('取消')),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop(true);
              _revokeKey(id);
            },
            child: const Text('吊销', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
