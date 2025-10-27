import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/api_client.dart';

class InterviewsScreen extends ConsumerStatefulWidget {
  const InterviewsScreen({super.key});

  @override
  ConsumerState<InterviewsScreen> createState() => _InterviewsScreenState();
}

class _InterviewsScreenState extends ConsumerState<InterviewsScreen> {
  List<Map<String, dynamic>> _interviews = [];
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
      final res = await dio.get('/api/employer/interviews/');
      setState(() {
        _interviews =
            List<Map<String, dynamic>>.from(res.data['interviews'] ?? []);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load interviews';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!));
    if (_interviews.isEmpty) {
      return Center(
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.event_busy_rounded,
                  size: 72, color: Color(0xFF1E3A8A)),
              SizedBox(height: 12),
              Text('No upcoming interviews')
            ]),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _interviews.length,
        itemBuilder: (context, i) => _card(_interviews[i]),
      ),
    );
  }

  Widget _card(Map<String, dynamic> itv) {
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
        leading: const Icon(Icons.event_rounded, color: Color(0xFF1E3A8A)),
        title: Text(itv['candidate_name'] ?? 'Candidate',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text((itv['datetime'] ?? '').toString()),
        trailing: Text(itv['status']?.toString().toUpperCase() ?? 'SCHEDULED',
            style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
