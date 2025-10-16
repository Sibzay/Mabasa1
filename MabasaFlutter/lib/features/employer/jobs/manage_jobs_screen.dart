import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/api_client.dart';
import 'job_applicants_swipe_screen.dart';

class ManageJobsScreen extends ConsumerStatefulWidget {
  const ManageJobsScreen({super.key});

  @override
  ConsumerState<ManageJobsScreen> createState() => _ManageJobsScreenState();
}

class _ManageJobsScreenState extends ConsumerState<ManageJobsScreen> {
  List<Map<String, dynamic>> _jobs = [];
  bool _loading = true;
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

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  Future<void> _loadJobs() async {
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
      final res = await dio.get('/api/employer/jobs/', queryParameters: params);
      setState(() {
        _jobs = List<Map<String, dynamic>>.from(res.data['jobs'] ?? []);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load jobs';
        _loading = false;
      });
    }
  }

  Future<void> _deleteJob(String jobId) async {
    try {
      final dio = await ApiClient().authed();
      await dio.delete('/api/employer/jobs/' + jobId + '/');
      _loadJobs();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Job deleted')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete job')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!));
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _openNewJobSheet,
        backgroundColor: const Color(0xFF7EC8FF),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          _buildCategoryBar(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadJobs,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _jobs.length,
                itemBuilder: (context, index) => _buildJobCard(_jobs[index]),
              ),
            ),
          ),
        ],
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
              _loadJobs();
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

  Widget _buildJobCard(Map<String, dynamic> job) {
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
        title: Text(job['title'] ?? 'Job Title',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(job['location'] ?? 'Location'),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          IconButton(
            icon: const Icon(Icons.edit_rounded, color: Color(0xFF7EC8FF)),
            onPressed: () => _openEditJobSheet(job),
          ),
          IconButton(
            icon: const Icon(Icons.delete_rounded, color: Colors.red),
            onPressed: () => _confirmDelete(job['id'].toString()),
          ),
        ]),
        onTap: () => _openJobApplicants(job),
      ),
    );
  }

  void _openNewJobSheet() {
    _openEditJobSheet({});
  }

  void _openEditJobSheet(Map<String, dynamic> job) {
    final titleController =
        TextEditingController(text: job['title']?.toString() ?? '');
    final locationController =
        TextEditingController(text: job['location']?.toString() ?? '');
    final descriptionController =
        TextEditingController(text: job['description']?.toString() ?? '');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24), topRight: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(job.isEmpty ? 'Create Job' : 'Edit Job',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title')),
              const SizedBox(height: 12),
              TextField(
                  controller: locationController,
                  decoration: const InputDecoration(labelText: 'Location')),
              const SizedBox(height: 12),
              TextField(
                  controller: descriptionController,
                  maxLines: 6,
                  decoration: const InputDecoration(labelText: 'Description')),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final payload = {
                      'title': titleController.text.trim(),
                      'location': locationController.text.trim(),
                      'description': descriptionController.text.trim(),
                    };
                    try {
                      final dio = await ApiClient().authed();
                      if (job.isEmpty) {
                        await dio.post('/api/employer/jobs/', data: payload);
                      } else {
                        await dio.put(
                            '/api/employer/jobs/' + job['id'].toString() + '/',
                            data: payload);
                      }
                      if (mounted) Navigator.pop(context);
                      _loadJobs();
                    } catch (e) {}
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7EC8FF),
                      foregroundColor: Colors.white),
                  child: Text(job.isEmpty ? 'Create' : 'Save Changes'),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(String jobId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Job?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteJob(jobId);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _openJobApplicants(Map<String, dynamic> job) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => JobApplicantsSwipeScreen(
        jobId: job['id'].toString(),
        jobTitle: job['title'] ?? 'Job',
      ),
    ));
  }
}
