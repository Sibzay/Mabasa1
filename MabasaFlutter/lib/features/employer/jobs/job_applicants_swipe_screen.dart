import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/api_client.dart';

class JobApplicantsSwipeScreen extends ConsumerStatefulWidget {
  final String jobId;
  final String jobTitle;
  const JobApplicantsSwipeScreen(
      {super.key, required this.jobId, required this.jobTitle});

  @override
  ConsumerState<JobApplicantsSwipeScreen> createState() =>
      _JobApplicantsSwipeScreenState();
}

class _JobApplicantsSwipeScreenState
    extends ConsumerState<JobApplicantsSwipeScreen> {
  List<Map<String, dynamic>> _applicants = [];
  bool _loading = true;
  int _currentIndex = 0;
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
      final res =
          await dio.get('/api/employer/jobs/' + widget.jobId + '/applicants/');
      setState(() {
        _applicants =
            List<Map<String, dynamic>>.from(res.data['applicants'] ?? []);
        _currentIndex = 0;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load applicants';
        _loading = false;
      });
    }
  }

  Future<void> _swipe(
      {required bool advance, required String applicantId}) async {
    try {
      final dio = await ApiClient().authed();
      await dio.post(
          '/api/employer/jobs/' + widget.jobId + '/applicants/swipe/',
          data: {
            'applicant_id': applicantId,
            'advance': advance,
          });
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      if (_currentIndex < _applicants.length - 1) {
        _currentIndex++;
      } else {
        _load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Applicants · ' + widget.jobTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _applicants.isEmpty
                  ? const Center(child: Text('No applicants yet'))
                  : _card(),
    );
  }

  Widget _card() {
    final a = _applicants[_currentIndex];
    return Column(children: [
      Expanded(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black87.withOpacity(0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 8)),
                ]),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        CircleAvatar(
                            radius: 28, child: Text((a['name'] ?? '?')[0])),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text(a['name'] ?? 'Applicant',
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold)),
                              Text(a['email'] ?? '',
                                  style: TextStyle(color: Colors.grey[700])),
                            ])),
                      ]),
                      const SizedBox(height: 16),
                      const Text('Summary',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(a['summary'] ?? 'No summary provided'),
                      const SizedBox(height: 16),
                      const Text('Experience',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ...List<String>.from(a['experience'] ?? [])
                          .map((e) => Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Text('• ' + e),
                              )),
                    ]),
              ),
            ),
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(bottom: 20.0),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          GestureDetector(
            onTap: () =>
                _swipe(advance: false, applicantId: a['id'].toString()),
            child: _circle(
                icon: Icons.close_rounded, color: Colors.red, outlined: true),
          ),
          const SizedBox(width: 28),
          GestureDetector(
            onTap: () => _swipe(advance: true, applicantId: a['id'].toString()),
            child: _circle(icon: Icons.check_rounded, color: Colors.green),
          ),
        ]),
      ),
    ]);
  }

  Widget _circle(
      {required IconData icon, required Color color, bool outlined = false}) {
    return Container(
      width: outlined ? 64 : 72,
      height: outlined ? 64 : 72,
      decoration: BoxDecoration(
        color: outlined ? Colors.white : color,
        shape: BoxShape.circle,
        border: outlined ? Border.all(color: color, width: 3) : null,
        boxShadow: [
          BoxShadow(
              color: Colors.black87.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 6))
        ],
      ),
      child: Icon(icon,
          color: outlined ? color : Colors.white, size: outlined ? 34 : 36),
    );
  }
}
