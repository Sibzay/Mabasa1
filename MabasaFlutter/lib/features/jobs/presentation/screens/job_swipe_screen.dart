import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/api_client.dart';
import 'package:dio/dio.dart';

class JobSwipeScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? data;

  const JobSwipeScreen({super.key, this.data});

  @override
  ConsumerState<JobSwipeScreen> createState() => _JobSwipeScreenState();
}

class _JobSwipeScreenState extends ConsumerState<JobSwipeScreen> {
  List<Map<String, dynamic>> _jobs = [];
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
  int _page = 1;
  bool _hasMore = true;
  String _search = '';
  String _location = '';
  final _searchController = TextEditingController();

  static final List<Map<String, dynamic>> _sampleJobs = [
    {
      'id': '1',
      'title': 'Senior Flutter Developer',
      'company': 'Tech Corp',
      'location': 'Remote',
      'salary': ' 80,000 -  120,000',
      'description':
          'We are looking for an experienced Flutter developer to join our team...',
      'type': 'Full-time',
      'requirements': ['3+ years Flutter', 'Clean architecture', 'Team player'],
    },
    {
      'id': '2',
      'title': 'UI/UX Designer',
      'company': 'Design Studio',
      'location': 'New York, NY',
      'salary': ' 60,000 -  90,000',
      'description':
          'Creative UI/UX designer needed for mobile app projects...',
      'type': 'Full-time',
      'requirements': ['Figma', 'Prototyping', 'Portfolio'],
    },
    {
      'id': '3',
      'title': 'Backend Developer',
      'company': 'StartupXYZ',
      'location': 'San Francisco, CA',
      'salary': ' 70,000 -  110,000',
      'description': 'Node.js and Python backend developer position...',
      'type': 'Full-time',
      'requirements': ['Node.js', 'Databases', 'APIs'],
    },
  ];

  @override
  void initState() {
    super.initState();
    _searchController.text = _search;
    _loadJobs(reset: true);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadJobs({bool reset = false}) async {
    if (reset) {
      setState(() {
        _loading = true;
        _error = null;
        _page = 1;
        _hasMore = true;
        _currentIndex = 0;
      });
    }
    try {
      final dio = await ApiClient().authed();
      final params = <String, dynamic>{'page': _page, 'page_size': 20};
      if (_selectedCategory != null && _selectedCategory != 'All')
        params['category'] = _selectedCategory;
      if (_search.isNotEmpty) params['search'] = _search;
      if (_location.isNotEmpty) params['location'] = _location;
      final res = await dio.get('/api/employee/jobs/recommended/',
          queryParameters: params);
      print('API Response: ${res.data}');
      print('Jobs data: ${res.data['jobs']}');
      final List<Map<String, dynamic>> loaded = List<Map<String, dynamic>>.from(
        (res.data is Map && res.data['jobs'] != null) ? res.data['jobs'] : [],
      );
      print('Loaded jobs: $loaded');
      setState(() {
        _jobs = reset ? loaded : [..._jobs, ...loaded];
        _currentIndex = 0;
        _loading = false;
        final total = (res.data['total'] as int?) ?? loaded.length;
        final pageSize = (res.data['page_size'] as int?) ?? loaded.length;
        _hasMore = (_page * pageSize) < total;
      });
    } on DioException catch (e) {
      setState(() {
        _error = 'Failed to load jobs: ${e.message ?? ''}';
        if (reset) _jobs = List<Map<String, dynamic>>.from(_sampleJobs);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load jobs';
        if (reset) _jobs = List<Map<String, dynamic>>.from(_sampleJobs);
        _loading = false;
      });
    }
  }

  Future<void> _loadMoreIfNeeded() async {
    if (!_hasMore) return;
    setState(() {
      _page += 1;
    });
    await _loadJobs();
  }

  Future<void> _swipeJob(bool interested, String jobId) async {
    try {
      final dio = await ApiClient().authed();
      await dio.post('/api/employee/jobs/swipe/', data: {
        'job_id': jobId,
        'interested': interested,
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save response')),
        );
      }
    } finally {
      if (!mounted) return;
      setState(() {
        if (_currentIndex < _jobs.length - 1) {
          _currentIndex++;
          if (_currentIndex >= _jobs.length - 3) {
            _loadMoreIfNeeded();
          }
        } else {
          _currentIndex = 0;
          _loadJobs(reset: true);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Search jobs...',
            hintStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
          ),
          textInputAction: TextInputAction.search,
          onSubmitted: (value) {
            _search = value.trim();
            _loadJobs(reset: true);
          },
        ),
        backgroundColor: const Color(0xFF2E86AB),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadJobs(reset: true),
            tooltip: 'Refresh jobs',
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _openFilterModal,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildCategoryBar(),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF1E40AF).withOpacity(0.3),
                    Colors.white,
                  ],
                ),
              ),
              child: SafeArea(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? _buildErrorState()
                        : _jobs.isEmpty
                            ? _buildEmptyState()
                            : _buildSwipeInterface(),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: const Icon(Icons.close, color: Colors.red),
                onPressed: () {
                  final jobId = _jobs.isNotEmpty
                      ? _jobs[_currentIndex]['id']?.toString() ?? ''
                      : '';
                  if (jobId.isNotEmpty) _swipeJob(false, jobId);
                },
              ),
              IconButton(
                icon: const Icon(Icons.favorite, color: Colors.green),
                onPressed: () {
                  final jobId = _jobs.isNotEmpty
                      ? _jobs[_currentIndex]['id']?.toString() ?? ''
                      : '';
                  if (jobId.isNotEmpty) _swipeJob(true, jobId);
                },
              ),
              IconButton(
                icon: const Icon(Icons.info_outline),
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openFilterModal() {
    final controller = TextEditingController(text: _location);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Filters',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  prefixIcon: Icon(Icons.place_rounded),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _location = controller.text.trim();
                    });
                    Navigator.pop(context);
                    _loadJobs(reset: true);
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      foregroundColor: Colors.white),
                  child: const Text('Apply Filters'),
                ),
              ),
            ],
          ),
        ),
      ),
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
              _loadJobs(reset: true);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFF1E3A8A) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF1E3A8A)),
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
          const Icon(Icons.error_outline, size: 64, color: Color(0xFF1E3A8A)),
          const SizedBox(height: 16),
          Text(
            _error ?? 'Unknown error',
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadJobs,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
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
        children: [
          const Icon(Icons.inbox_rounded, size: 80, color: Color(0xFF1E3A8A)),
          const SizedBox(height: 24),
          const Text(
            'No More Jobs',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Check back later for new opportunities',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _loadJobs,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwipeInterface() {
    final job = _jobs[_currentIndex];

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Find Your Match',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A8A).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_currentIndex + 1}/${_jobs.length}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Job Card
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Company Logo/Icon (fallback to first letter)
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E3A8A).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Text(
                            (job['company'] ?? 'C')[0].toString(),
                            style: const TextStyle(
                              fontSize: 32,
                              color: Color(0xFF1E3A8A),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Job Title
                      Text(
                        job['title'] ?? 'Job Title',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Company Name
                      Text(
                        job['company'] ?? 'Company Name',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Info Row
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _buildInfoChip(
                            Icons.location_on_rounded,
                            job['location'] ?? 'Location',
                          ),
                          _buildInfoChip(
                            Icons.work_outline_rounded,
                            job['type'] ?? 'Full-time',
                          ),
                          _buildInfoChip(
                            Icons.attach_money_rounded,
                            job['salary'] ?? 'Competitive',
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Description
                      const Text(
                        'About this role',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        job['description'] ?? 'No description available',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey[700],
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Requirements
                      if (job['requirements'] != null) ...[
                        const Text(
                          'Requirements',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...List<String>.from(job['requirements'] ?? [])
                            .map((req) {
                          print(
                              'Requirement item: $req, type: ${req.runtimeType}');
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  size: 20,
                                  color: Color(0xFF1E3A8A),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    req,
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // Swipe Buttons
        Padding(
          padding: const EdgeInsets.all(32.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Reject Button
              GestureDetector(
                onTap: () {
                  final jobId = job['id']?.toString() ?? '';
                  if (jobId.isNotEmpty) _swipeJob(false, jobId);
                },
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.red.shade300, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Colors.red,
                    size: 36,
                  ),
                ),
              ),
              const SizedBox(width: 40),

              // Accept Button
              GestureDetector(
                onTap: () {
                  final jobId = job['id']?.toString() ?? '';
                  if (jobId.isNotEmpty) _swipeJob(true, jobId);
                },
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1E3A8A).withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E3A8A).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF1E3A8A)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E3A8A),
            ),
          ),
        ],
      ),
    );
  }
}
