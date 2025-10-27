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
                  size: 72, color: Color(0xFF1E3A8A)),
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
      child: Card(
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: const Color(0xFF1E3A8A),
                    child: Text(
                      (c['name'] ?? '?')[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c['name'] ?? 'Candidate',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          c['title'] ?? 'No title provided',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                        if (c['location'] != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            c['location'],
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              if (c['summary'] != null &&
                  c['summary'].toString().isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Summary',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  c['summary'],
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (c['skills'] != null &&
                  _getSkillsList(c['skills']).isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Skills',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children:
                      _getSkillsList(c['skills']).take(5).map<Widget>((skill) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E3A8A).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(0xFF1E3A8A).withOpacity(0.3)),
                      ),
                      child: Text(
                        skill,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF1E3A8A),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _viewResume(c),
                      icon: const Icon(Icons.description, size: 18),
                      label: const Text('View Resume'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1E3A8A),
                        side: const BorderSide(color: Color(0xFF1E3A8A)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _scheduleInterview(c),
                      icon: const Icon(Icons.event, size: 18),
                      label: const Text('Interview'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _confirmDelete(c),
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    tooltip: 'Remove from shortlist',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _viewResume(Map<String, dynamic> candidate) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${candidate['name']} - Resume'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (candidate['summary'] != null) ...[
                const Text(
                  'Professional Summary',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(candidate['summary']),
                const SizedBox(height: 16),
              ],
              if (candidate['skills'] != null &&
                  _getSkillsList(candidate['skills']).isNotEmpty) ...[
                const Text(
                  'Skills',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children:
                      _getSkillsList(candidate['skills']).map<Widget>((skill) {
                    return Chip(
                      label: Text(skill),
                      backgroundColor: const Color(0xFF1E3A8A).withOpacity(0.1),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],
              if (candidate['resume_url'] != null &&
                  candidate['resume_url'].toString().isNotEmpty) ...[
                const Text(
                  'Resume Document',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    // In a real app, you'd open the resume URL
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content:
                              Text('Resume URL: ${candidate['resume_url']}')),
                    );
                  },
                  icon: const Icon(Icons.download),
                  label: const Text('Download Resume'),
                ),
              ] else ...[
                const Text(
                  'No resume document available',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _scheduleInterview(Map<String, dynamic> candidate) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Schedule Interview'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Schedule interview with ${candidate['name']}?'),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Interview Date & Time',
                hintText: 'e.g., 2024-01-15 14:30',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final dio = await ApiClient().authed();
                await dio.post('/api/employer/interviews/schedule/',
                    data: {'candidate_id': candidate['id']});
                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Interview scheduled successfully!')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            'Error scheduling interview: ${e.toString()}')),
                  );
                }
              }
            },
            child: const Text('Schedule'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(Map<String, dynamic> candidate) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove from Shortlist'),
        content: Text(
            'Are you sure you want to remove ${candidate['name']} from the shortlist?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _remove(candidate['id'].toString());
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Candidate removed from shortlist')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  List<String> _getSkillsList(dynamic skills) {
    if (skills == null) return [];

    if (skills is List) {
      return skills.map((s) => s.toString()).toList();
    }

    if (skills is String) {
      // Handle case where skills might be a comma-separated string
      return skills
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }

    return [];
  }
}
