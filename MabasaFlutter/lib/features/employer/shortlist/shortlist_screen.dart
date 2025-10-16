import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/api_client.dart';

class ShortlistScreen extends ConsumerStatefulWidget {
  const ShortlistScreen({super.key});

  @override
  ConsumerState<ShortlistScreen> createState() => _ShortlistScreenState();
}

class _ShortlistScreenState extends ConsumerState<ShortlistScreen> {
  List<Map<String, dynamic>> _shortlist = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final dio = await ApiClient().authed();
      final res = await dio.get('/api/employer/shortlist/');
      setState(() {
        _shortlist =
            List<Map<String, dynamic>>.from(res.data['candidates'] ?? []);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load shortlist';
        _loading = false;
      });
    }
  }

  Future<void> _remove(String candidateId) async {
    try {
      final dio = await ApiClient().authed();
      await dio.delete('/api/employer/shortlist/' + candidateId + '/');
      _load();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!));
    if (_shortlist.isEmpty) {
      return Center(
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.bookmark_border_rounded,
                  size: 72, color: Color(0xFF7EC8FF)),
              SizedBox(height: 12),
              Text('No shortlisted candidates')
            ]),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _shortlist.length,
        itemBuilder: (context, i) => _card(_shortlist[i]),
      ),
    );
  }

  Widget _card(Map<String, dynamic> c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 6)),
          ]),
      child: ListTile(
        leading: CircleAvatar(child: Text((c['name'] ?? '?')[0])),
        title: Text(c['name'] ?? 'Candidate',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(c['title'] ?? ''),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          IconButton(
            icon: const Icon(Icons.event_rounded, color: Colors.green),
            onPressed: () async {
              final dio = await ApiClient().authed();
              await dio.post('/api/employer/interviews/schedule/',
                  data: {'candidate_id': c['id']});
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Interview scheduled (stub)')));
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
            onPressed: () => _remove(c['id'].toString()),
          ),
        ]),
      ),
    );
  }
}
