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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  void _openEditJobSheet(Map<String, dynamic> job) {
    final titleController =
        TextEditingController(text: job['title']?.toString() ?? '');
    final locationController =
        TextEditingController(text: job['location']?.toString() ?? '');
    final descriptionController =
        TextEditingController(text: job['description']?.toString() ?? '');
    final certificationsController = TextEditingController(
        text: job['required_certifications']?.toString() ?? '');
    final educationController =
        TextEditingController(text: job['education_level']?.toString() ?? '');
    final salaryController =
        TextEditingController(text: job['salary_amount']?.toString() ?? '');
    final dutiesController = TextEditingController(
        text: job['duties_responsibilities']?.toString() ?? '');
    final hoursController =
        TextEditingController(text: job['expected_hours']?.toString() ?? '');
    final daysController =
        TextEditingController(text: job['work_days']?.toString() ?? '');

    String selectedWorkType = job['work_type']?.toString() ?? 'office';
    String selectedCurrency = job['salary_currency']?.toString() ?? 'USD';
    String selectedCategory = job['category']?.toString() ?? 'ICT';

    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => DraggableScrollableSheet(
          initialChildSize: 0.95,
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
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(job.isEmpty ? 'Create Job' : 'Edit Job',
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87)),
                    const SizedBox(height: 16),

                    // Basic Information
                    _buildSectionTitle('Basic Information'),
                    TextField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'Job Title',
                          border: OutlineInputBorder(),
                          labelStyle: TextStyle(color: Colors.black87),
                        )),
                    const SizedBox(height: 12),
                    TextField(
                        controller: locationController,
                        decoration: const InputDecoration(
                          labelText: 'Location',
                          border: OutlineInputBorder(),
                          labelStyle: TextStyle(color: Colors.black87),
                        )),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                        labelStyle: TextStyle(color: Colors.black87),
                      ),
                      items: [
                        'ICT',
                        'Accountancy',
                        'Administration',
                        'Manufacturing',
                        'HR',
                        'Sales',
                        'Logistics'
                      ]
                          .map((category) => DropdownMenuItem(
                              value: category, child: Text(category)))
                          .toList(),
                      onChanged: (value) =>
                          setState(() => selectedCategory = value!),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                        controller: descriptionController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Job Description',
                          border: OutlineInputBorder(),
                          labelStyle: TextStyle(color: Colors.black87),
                        )),

                    const SizedBox(height: 20),

                    // Requirements & Qualifications
                    _buildSectionTitle('Requirements & Qualifications'),
                    TextField(
                        controller: certificationsController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Required Certifications',
                          border: OutlineInputBorder(),
                          labelStyle: TextStyle(color: Colors.black87),
                        )),
                    const SizedBox(height: 12),
                    TextField(
                        controller: educationController,
                        decoration: const InputDecoration(
                          labelText: 'Education Level Required',
                          border: OutlineInputBorder(),
                          labelStyle: TextStyle(color: Colors.black87),
                        )),

                    const SizedBox(height: 20),

                    // Salary Information
                    _buildSectionTitle('Salary Information'),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                              controller: salaryController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Salary Amount',
                                border: OutlineInputBorder(),
                                labelStyle: TextStyle(color: Colors.black87),
                              )),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedCurrency,
                            decoration: const InputDecoration(
                              labelText: 'Currency',
                              border: OutlineInputBorder(),
                              labelStyle: TextStyle(color: Colors.black87),
                            ),
                            items: ['USD', 'ZWD', 'EUR', 'GBP']
                                .map((currency) => DropdownMenuItem(
                                    value: currency, child: Text(currency)))
                                .toList(),
                            onChanged: (value) =>
                                setState(() => selectedCurrency = value!),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Work Details
                    _buildSectionTitle('Work Details'),
                    TextField(
                        controller: dutiesController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Duties and Responsibilities',
                          border: OutlineInputBorder(),
                          labelStyle: TextStyle(color: Colors.black87),
                        )),
                    const SizedBox(height: 12),
                    TextField(
                        controller: hoursController,
                        decoration: const InputDecoration(
                          labelText: 'Expected Hours of Work',
                          border: OutlineInputBorder(),
                          labelStyle: TextStyle(color: Colors.black87),
                        )),
                    const SizedBox(height: 12),
                    TextField(
                        controller: daysController,
                        decoration: const InputDecoration(
                          labelText: 'Work Days (e.g., Monday-Friday)',
                          border: OutlineInputBorder(),
                          labelStyle: TextStyle(color: Colors.black87),
                        )),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedWorkType,
                      decoration: const InputDecoration(
                        labelText: 'Work Type',
                        border: OutlineInputBorder(),
                        labelStyle: TextStyle(color: Colors.black87),
                      ),
                      items: [
                        DropdownMenuItem(
                            value: 'office', child: Text('In Office')),
                        DropdownMenuItem(
                            value: 'remote', child: Text('Remote')),
                        DropdownMenuItem(
                            value: 'hybrid', child: Text('Hybrid')),
                      ],
                      onChanged: (value) =>
                          setState(() => selectedWorkType = value!),
                    ),

                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading
                            ? null
                            : () async {
                                if (titleController.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content:
                                            Text('Please enter a job title')),
                                  );
                                  return;
                                }

                                setState(() => isLoading = true);

                                final payload = {
                                  'title': titleController.text.trim(),
                                  'location': locationController.text.trim(),
                                  'description':
                                      descriptionController.text.trim(),
                                  'category': selectedCategory,
                                  'required_certifications':
                                      certificationsController.text.trim(),
                                  'education_level':
                                      educationController.text.trim(),
                                  'salary_amount':
                                      salaryController.text.trim().isNotEmpty
                                          ? double.tryParse(
                                              salaryController.text.trim())
                                          : null,
                                  'salary_currency': selectedCurrency,
                                  'duties_responsibilities':
                                      dutiesController.text.trim(),
                                  'expected_hours': hoursController.text.trim(),
                                  'work_days': daysController.text.trim(),
                                  'work_type': selectedWorkType,
                                };

                                try {
                                  final dio = await ApiClient().authed();
                                  if (job.isEmpty) {
                                    await dio.post('/api/employer/jobs/',
                                        data: payload);
                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Job created successfully!')),
                                      );
                                    }
                                  } else {
                                    await dio.put(
                                        '/api/employer/jobs/' +
                                            job['id'].toString() +
                                            '/',
                                        data: payload);
                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Job updated successfully!')),
                                      );
                                    }
                                  }
                                  if (mounted) Navigator.pop(context);
                                  _loadJobs();
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content:
                                              Text('Error: ${e.toString()}')),
                                    );
                                  }
                                } finally {
                                  if (mounted)
                                    setState(() => isLoading = false);
                                }
                              },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7EC8FF),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16)),
                        child: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )
                            : Text(job.isEmpty ? 'Create Job' : 'Save Changes'),
                      ),
                    ),
                  ]),
            ),
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
