import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/api_client.dart';
import 'dart:async';

class InterviewsScreen extends ConsumerStatefulWidget {
  const InterviewsScreen({super.key});

  @override
  ConsumerState<InterviewsScreen> createState() => _InterviewsScreenState();
}

class _InterviewsScreenState extends ConsumerState<InterviewsScreen> {
  List<Map<String, dynamic>> _interviews = [];
  bool _loading = true;
  String? _error;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _load();
    _startCountdownTimer();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdownTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
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
    final scheduledAt = DateTime.tryParse(itv['scheduled_at'] ?? '');
    final countdownText =
        scheduledAt != null ? _getCountdownText(scheduledAt) : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black87.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 6)),
          ]),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.event_rounded, color: Color(0xFF1E3A8A)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        itv['candidate_name'] ?? 'Candidate',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        itv['job_title'] ?? 'Job Position',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(itv['status']).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    (itv['status'] ?? 'scheduled').toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(itv['status']),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.schedule, size: 16, color: Colors.black54),
                const SizedBox(width: 4),
                Text(
                  _formatDateTime(scheduledAt),
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ],
            ),
            if (itv['location'] != null &&
                itv['location'].toString().isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on,
                      size: 16, color: Colors.black54),
                  const SizedBox(width: 4),
                  Text(
                    itv['location'],
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.timer, size: 16, color: Color(0xFF1E3A8A)),
                const SizedBox(width: 4),
                Text(
                  countdownText,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: scheduledAt != null &&
                            scheduledAt.isBefore(DateTime.now())
                        ? Colors.red
                        : const Color(0xFF1E3A8A),
                  ),
                ),
              ],
            ),
            if (itv['notes'] != null && itv['notes'].toString().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Notes: ${itv['notes']}',
                style: const TextStyle(fontSize: 13, color: Colors.black54),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _editInterview(itv),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF1E3A8A),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _deleteInterview(itv),
                  icon: const Icon(Icons.delete, size: 16),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getCountdownText(DateTime scheduledAt) {
    final now = DateTime.now();
    final difference = scheduledAt.difference(now);

    if (difference.isNegative) {
      return 'Interview time has passed';
    }

    final days = difference.inDays;
    final hours = difference.inHours % 24;
    final minutes = difference.inMinutes % 60;
    final seconds = difference.inSeconds % 60;

    if (days > 0) {
      return '$days days, $hours hours remaining';
    } else if (hours > 0) {
      return '$hours hours, $minutes minutes remaining';
    } else if (minutes > 0) {
      return '$minutes minutes, $seconds seconds remaining';
    } else {
      return '$seconds seconds remaining';
    }
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'Date not set';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'scheduled':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _editInterview(Map<String, dynamic> interview) {
    final TextEditingController dateTimeController = TextEditingController(
      text: interview['scheduled_at'] ?? '',
    );
    final TextEditingController notesController = TextEditingController(
      text: interview['notes'] ?? '',
    );
    final TextEditingController locationController = TextEditingController(
      text: interview['location'] ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Interview'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Edit interview with ${interview['candidate_name']}'),
              const SizedBox(height: 16),
              TextField(
                controller: dateTimeController,
                decoration: const InputDecoration(
                  labelText: 'Interview Date & Time',
                  hintText: 'YYYY-MM-DD HH:MM (e.g., 2024-01-15 14:30)',
                ),
                keyboardType: TextInputType.datetime,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: locationController,
                decoration: const InputDecoration(
                  labelText: 'Location (optional)',
                  hintText: 'e.g., Zoom, Office, etc.',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  hintText: 'Additional notes for the interview',
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (dateTimeController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter date and time')),
                );
                return;
              }

              try {
                final dio = await ApiClient().authed();
                final response = await dio
                    .put('/api/employer/interviews/${interview['id']}/', data: {
                  'scheduled_at': dateTimeController.text,
                  'notes': notesController.text,
                  'location': locationController.text,
                });

                if (mounted) {
                  Navigator.of(context).pop();
                  _load(); // Refresh the list
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Interview updated successfully')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content:
                            Text('Error updating interview: ${e.toString()}')),
                  );
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _deleteInterview(Map<String, dynamic> interview) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Interview'),
        content: Text(
            'Are you sure you want to delete the interview with ${interview['candidate_name']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final dio = await ApiClient().authed();
                await dio
                    .delete('/api/employer/interviews/${interview['id']}/');
                Navigator.of(context).pop();
                _load(); // Refresh the list
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Interview deleted successfully')),
                  );
                }
              } catch (e) {
                Navigator.of(context).pop();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content:
                            Text('Error deleting interview: ${e.toString()}')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
