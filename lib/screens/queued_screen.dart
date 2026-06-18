import 'package:flutter/material.dart';
import '../services/offline_queue.dart';
import '../services/sync_manager.dart';

class QueuedScreen extends StatefulWidget {
  const QueuedScreen({super.key});

  @override
  State<QueuedScreen> createState() => _QueuedScreenState();
}

class _QueuedScreenState extends State<QueuedScreen> {
  final OfflineQueue _queue = OfflineQueue();
  final SyncManager _sync = SyncManager();
  List<Map<String, dynamic>> _items = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _items = await _queue.list();
    setState(() => _loading = false);
  }

  Future<void> _syncAll() async {
    setState(() => _loading = true);
    await _sync.syncAll();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cola offline')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const Center(child: Text('No hay items en la cola'))
              : ListView.separated(
                  itemCount: _items.length,
                  separatorBuilder: (_, _) => const Divider(),
                  itemBuilder: (context, index) {
                    final it = _items[index];
                    return ListTile(
                      title: Text(it['payload']?['client_name'] ?? 'Solicitud sin nombre'),
                      subtitle: Text('Creada: ${it['payload']?['created_at'] ?? ''}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () async {
                          await _queue.removeAt(index);
                          await _load();
                        },
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.sync),
        label: const Text('Sincronizar'),
        onPressed: _syncAll,
      ),
    );
  }
}
