import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/api_client.dart';
import '../candidates/candidate_swipe_screen.dart';
import '../jobs/manage_jobs_screen.dart';
import '../shortlist/shortlist_screen.dart';
import '../interviews/interviews_screen.dart';

class EmployerDashboardScreen extends ConsumerStatefulWidget {
  const EmployerDashboardScreen({super.key});

  @override
  ConsumerState<EmployerDashboardScreen> createState() =>
      _EmployerDashboardScreenState();
}

class _EmployerDashboardScreenState
    extends ConsumerState<EmployerDashboardScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final dio = await ApiClient().authed();
      final res = await dio.get('/api/auth/dashboard/');
      setState(() {
        _data = res.data as Map<String, dynamic>;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load dashboard';
      });
    } finally {
      if (mounted)
        setState(() {
          _loading = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employer'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Candidates'),
            Tab(text: 'Jobs'),
            Tab(text: 'Shortlist'),
            Tab(text: 'Interviews'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : TabBarView(
                  controller: _tabController,
                  children: const [
                    CandidateSwipeScreen(),
                    ManageJobsScreen(),
                    ShortlistScreen(),
                    InterviewsScreen(),
                  ],
                ),
    );
  }
}
