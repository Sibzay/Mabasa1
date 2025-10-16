import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/api_client.dart';
import 'package:dio/dio.dart';

class CandidateSwipeScreen extends ConsumerStatefulWidget {
  const CandidateSwipeScreen({super.key});

  @override
  ConsumerState<CandidateSwipeScreen> createState() =>
      _CandidateSwipeScreenState();
}

class _CandidateSwipeScreenState extends ConsumerState<CandidateSwipeScreen> {
  List<Map<String, dynamic>> _candidates = [];
  bool _loading = true;
  int _currentIndex = 0;
  String? _error;
  String? _selectedCategory;
  final List<String> _categories = [
    'All',
    'Accountancy',
    'Administration',
    'ICT',
    'Manufacturing',
    'HR',
    'Sales',
    'Logistics'
  ];

  static final List<Map<String, dynamic>> _sampleCandidates = [
    {
      'id': 'c1',
      'name': 'Tariro Moyo',
      'title': 'Flutter Developer',
      'location': 'Harare',
      'experience': '3 years',
      'skills': ['Dart', 'Flutter', 'REST APIs'],
      'bio': 'Passionate mobile dev building clean, scalable apps.',
    },
    {
      'id': 'c2',
      'name': 'Kuda Ncube',
      'title': 'Backend Engineer',
      'location': 'Bulawayo',
      'experience': '5 years',
      'skills': ['Python', 'Django', 'PostgreSQL'],
      'bio': 'API-first developer focused on performance and reliability.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadCandidates();
  }

  Future<void> _loadCandidates() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final dio = await ApiClient().authed();
      final params = <String, dynamic>{};
      if (_selectedCategory != null && _selectedCategory != 'All') {
        params['category'] = _selectedCategory;
      }
      final res = await dio.get('/api/employer/candidates/recommended/',
          queryParameters: params);
      final List<Map<String, dynamic>> loaded = List<Map<String, dynamic>>.from(
        (res.data is Map && res.data['candidates'] != null)
            ? res.data['candidates']
            : [],
      );
      setState(() {
        _candidates = loaded.isNotEmpty
            ? loaded
            : List<Map<String, dynamic>>.from(_sampleCandidates);
        _currentIndex = 0;
        _loading = false;
      });
    } on DioException catch (e) {
      setState(() {
        _error = 'Failed to load candidates: ${e.message ?? ''}';
        _candidates = List<Map<String, dynamic>>.from(_sampleCandidates);
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _error = 'Failed to load candidates';
        _candidates = List<Map<String, dynamic>>.from(_sampleCandidates);
        _loading = false;
      });
    }
  }

  Future<void> _swipeCandidate(
      {required bool shortlist, required String candidateId}) async {
    try {
      final dio = await ApiClient().authed();
      await dio.post('/api/employer/candidates/swipe/', data: {
        'candidate_id': candidateId,
        'shortlist': shortlist,
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save action')),
        );
      }
    } finally {
      if (!mounted) return;
      setState(() {
        if (_currentIndex < _candidates.length - 1) {
          _currentIndex++;
        } else {
          _currentIndex = 0;
          _loadCandidates();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildCategoryBar(),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? _buildErrorState()
                  : _candidates.isEmpty
                      ? _buildEmptyState()
                      : _buildSwipeInterface(),
        ),
      ],
    );
  }

  Widget _buildCategoryBar() {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final selected = (_selectedCategory ?? 'All') == cat;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = cat;
              });
              _loadCandidates();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFF7EC8FF) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF7EC8FF)),
              ),
              child: Text(
                cat,
                style: TextStyle(
                  color: selected ? Colors.white : const Color(0xFF1C6BA8),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: _categories.length,
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Color(0xFF7EC8FF)),
          const SizedBox(height: 12),
          Text(_error ?? 'Unknown error',
              style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadCandidates,
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7EC8FF),
                foregroundColor: Colors.white),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.people_outline, size: 80, color: Color(0xFF7EC8FF)),
          SizedBox(height: 16),
          Text('No Candidates Right Now',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSwipeInterface() {
    final candidate = _candidates[_currentIndex];
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Find Candidates',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    color: const Color(0xFF7EC8FF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20)),
                child: Text('${_currentIndex + 1}/${_candidates.length}',
                    style: const TextStyle(
                        color: Color(0xFF7EC8FF), fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.06),
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
                              radius: 28, child: Text(candidate['name'][0])),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(candidate['name'],
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold)),
                                  Text(candidate['title'] ?? 'Candidate',
                                      style:
                                          TextStyle(color: Colors.grey[700])),
                                ]),
                          ),
                        ]),
                        const SizedBox(height: 16),
                        Wrap(spacing: 8, runSpacing: 8, children: [
                          _chip(Icons.place_rounded,
                              candidate['location'] ?? 'Location'),
                          _chip(Icons.work_history_rounded,
                              candidate['experience'] ?? 'Experience'),
                        ]),
                        const SizedBox(height: 16),
                        const Text('Skills',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Wrap(spacing: 8, runSpacing: 8, children: [
                          ...List<String>.from(candidate['skills'] ?? [])
                              .map((s) => Chip(label: Text(s))),
                        ]),
                        const SizedBox(height: 16),
                        const Text('About',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(candidate['bio'] ?? 'No bio'),
                      ]),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            GestureDetector(
              onTap: () => _swipeCandidate(
                  shortlist: false, candidateId: candidate['id'].toString()),
              child: _actionCircle(
                  icon: Icons.close_rounded,
                  color: Colors.red,
                  size: 36,
                  outlined: true),
            ),
            const SizedBox(width: 28),
            GestureDetector(
              onTap: () => _swipeCandidate(
                  shortlist: true, candidateId: candidate['id'].toString()),
              child: _actionCircle(
                  icon: Icons.check_rounded, color: Colors.green, size: 40),
            ),
            const SizedBox(width: 28),
            GestureDetector(
              onTap: () {
                _showCandidateDetails(candidate);
              },
              child: _actionCircle(
                  icon: Icons.info_outline_rounded,
                  color: const Color(0xFF7EC8FF),
                  size: 32,
                  outlined: true),
            ),
          ]),
        ),
      ],
    );
  }

  Widget _chip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
          color: const Color(0xFF7EC8FF).withOpacity(0.08),
          borderRadius: BorderRadius.circular(16)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 16, color: const Color(0xFF7EC8FF)),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(
                color: Color(0xFF1C6BA8), fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _actionCircle(
      {required IconData icon,
      required Color color,
      required double size,
      bool outlined = false}) {
    return Container(
      width: outlined ? 64 : 72,
      height: outlined ? 64 : 72,
      decoration: BoxDecoration(
        color: outlined ? Colors.white : color,
        shape: BoxShape.circle,
        border: outlined ? Border.all(color: color, width: 3) : null,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 6))
        ],
      ),
      child: Icon(icon, color: outlined ? color : Colors.white, size: size),
    );
  }

  void _showCandidateDetails(Map<String, dynamic> c) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              CircleAvatar(radius: 28, child: Text(c['name'][0])),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(c['name'],
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(c['title'] ?? '-',
                        style: TextStyle(color: Colors.grey[700])),
                  ])),
            ]),
            const SizedBox(height: 16),
            const Text('Profile Summary',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(c['bio'] ?? 'No bio'),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  try {
                    final dio = await ApiClient().authed();
                    await dio.post('/api/employer/interviews/schedule/', data: {
                      'candidate_id': c['id'],
                    });
                    if (mounted) Navigator.pop(context);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Interview scheduled (stub)')));
                    }
                  } catch (_) {}
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7EC8FF),
                    foregroundColor: Colors.white),
                child: const Text('Schedule Interview'),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
