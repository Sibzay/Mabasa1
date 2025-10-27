# Pseudo Code for Mabasa Job Platform Modules

This document contains pseudo code representations for all major modules of the Mabasa job application platform, including both backend (Django) and frontend (Flutter) implementations.

## 1. Authentication Module

### Backend (Django) - User Registration
```python
# accounts/views.py - User Registration
@api_view(['POST'])
@permission_classes([permissions.AllowAny])
def register(request):
    """
    Register a new user (Employee or Employer)
    """
    data = request.data

    # Validate required fields
    required_fields = ['username', 'email', 'password', 'role']
    for field in required_fields:
        if field not in data:
            return Response({'error': f'{field} is required'}, status=400)

    # Check if user already exists
    if User.objects.filter(username=data['username']).exists():
        return Response({'error': 'Username already exists'}, status=400)

    if User.objects.filter(email=data['email']).exists():
        return Response({'error': 'Email already exists'}, status=400)

    # Validate role
    if data['role'] not in ['employee', 'employer']:
        return Response({'error': 'Invalid role'}, status=400)

    try:
        # Create user
        user = User.objects.create_user(
            username=data['username'],
            email=data['email'],
            password=data['password'],
            first_name=data.get('first_name', ''),
            last_name=data.get('last_name', ''),
            role=data['role']
        )

        # Generate JWT tokens
        refresh = RefreshToken.for_user(user)
        tokens = {
            'refresh': str(refresh),
            'access': str(refresh.access_token),
            'user': UserSerializer(user).data
        }

        return Response(tokens, status=201)

    except Exception as e:
        return Response({'error': str(e)}, status=400)
```

### Backend (Django) - User Login
```python
# accounts/views.py - User Login
@api_view(['POST'])
@permission_classes([permissions.AllowAny])
def login(request):
    """
    Authenticate user and return JWT tokens
    """
    data = request.data
    username = data.get('username')
    password = data.get('password')

    if not username or not password:
        return Response({'error': 'Username and password are required'}, status=400)

    # Authenticate user
    user = authenticate(username=username, password=password)

    if user is None:
        return Response({'error': 'Invalid credentials'}, status=401)

    if not user.is_active:
        return Response({'error': 'Account is disabled'}, status=401)

    # Generate JWT tokens
    refresh = RefreshToken.for_user(user)
    tokens = {
        'refresh': str(refresh),
        'access': str(refresh.access_token),
        'user': UserSerializer(user).data
    }

    return Response(tokens, status=200)
```

### Frontend (Flutter) - Auth Service
```dart
// lib/core/services/auth_service.dart
class AuthService {
  final ApiClient _client = ApiClient();

  Future<Map<String, dynamic>> login({
    required String usernameOrEmail,
    required String password
  }) async {
    try {
      final response = await _client.raw.post('/api/auth/token/', data: {
        'username': usernameOrEmail,
        'password': password,
      });

      final data = response.data as Map<String, dynamic>;
      await _saveTokens(data);
      return data['user'] as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Login failed: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    required String role,
    String? firstName,
    String? lastName,
  }) async {
    try {
      final response = await _client.raw.post('/api/auth/register/', data: {
        'username': username,
        'email': email,
        'password': password,
        'first_name': firstName,
        'last_name': lastName,
        'role': role,
      });

      // Auto-login after successful registration
      await login(usernameOrEmail: username, password: password);
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Registration failed: ${e.toString()}');
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    await prefs.remove('role');
  }

  Future<void> _saveTokens(Map<String, dynamic> tokenResponse) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', tokenResponse['access']);
    await prefs.setString('refresh_token', tokenResponse['refresh']);

    final user = tokenResponse['user'] as Map<String, dynamic>;
    if (user['role'] != null) {
      await prefs.setString('role', user['role'] as String);
    }
  }
}
```

## 2. Job Management Module

### Backend (Django) - Job CRUD Operations
```python
# recruitment/views.py - Job Management
@api_view(['GET', 'POST'])
@permission_classes([permissions.IsAuthenticated])
def jobs(request):
    """
    List employer's jobs or create new job
    """
    if request.method == 'GET':
        # Get employer's jobs with optional category filter
        jobs = Job.objects.filter(employer=request.user).order_by('-created_at')

        category = request.query_params.get('category')
        if category and category != 'All':
            jobs = jobs.filter(category=category)

        serializer = JobSerializer(jobs, many=True)
        return Response({'jobs': serializer.data})

    else:  # POST - Create new job
        serializer = JobSerializer(data=request.data)
        if serializer.is_valid():
            job = serializer.save(employer=request.user)
            return Response(JobSerializer(job).data, status=201)
        return Response(serializer.errors, status=400)

@api_view(['PUT', 'DELETE'])
@permission_classes([permissions.IsAuthenticated])
def job_detail(request, job_id):
    """
    Update or delete a specific job
    """
    try:
        job = Job.objects.get(pk=job_id, employer=request.user)
    except Job.DoesNotExist:
        return Response({'error': 'Job not found'}, status=404)

    if request.method == 'PUT':
        serializer = JobSerializer(job, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=400)

    else:  # DELETE
        job.delete()
        return Response(status=204)
```

### Backend (Django) - Job Recommendations for Employees
```python
# recruitment/views.py - Employee Job Recommendations
@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def employee_jobs_recommended(request):
    """
    Get recommended jobs for employees with filtering and pagination
    """
    # Base queryset
    jobs = Job.objects.filter(is_open=True).order_by('-created_at')

    # Apply filters
    category = request.query_params.get('category')
    search = request.query_params.get('search')
    location = request.query_params.get('location')

    if category and category != 'All':
        jobs = jobs.filter(category=category)
    if search:
        jobs = jobs.filter(
            Q(title__icontains=search) |
            Q(description__icontains=search) |
            Q(employer__first_name__icontains=search) |
            Q(employer__last_name__icontains=search)
        )
    if location:
        jobs = jobs.filter(location__icontains=location)

    # Pagination
    try:
        page = int(request.query_params.get('page', '1'))
        page_size = int(request.query_params.get('page_size', '20'))
    except ValueError:
        page, page_size = 1, 20

    total = jobs.count()
    start = (page - 1) * page_size
    end = start + page_size
    jobs_page = jobs[start:end]

    # Format response data
    data = []
    for job in jobs_page:
        data.append({
            'id': job.id,
            'title': job.title,
            'company': job.employer.get_full_name() or job.employer.username,
            'location': job.location,
            'salary': job.salary_range or 'Competitive',
            'description': job.description,
            'type': 'Full-time',
            'requirements': job.requirements,
        })

    return Response({
        'jobs': data,
        'page': page,
        'page_size': page_size,
        'total': total
    })
```

### Frontend (Flutter) - Job Swipe Screen
```dart
// lib/features/jobs/presentation/screens/job_swipe_screen.dart
class JobSwipeScreen extends ConsumerStatefulWidget {
  const JobSwipeScreen({super.key});

  @override
  ConsumerState<JobSwipeScreen> createState() => _JobSwipeScreenState();
}

class _JobSwipeScreenState extends ConsumerState<JobSwipeScreen> {
  List<Map<String, dynamic>> _jobs = [];
  bool _loading = true;
  int _currentIndex = 0;
  String? _selectedCategory;
  String _search = '';
  String _location = '';

  @override
  void initState() {
    super.initState();
    _loadJobs(reset: true);
  }

  Future<void> _loadJobs({bool reset = false}) async {
    if (reset) {
      setState(() {
        _loading = true;
        _currentIndex = 0;
      });
    }

    try {
      final dio = await ApiClient().authed();
      final params = <String, dynamic>{
        'page': reset ? 1 : (_jobs.length ~/ 20) + 1,
        'page_size': 20
      };

      if (_selectedCategory != null && _selectedCategory != 'All') {
        params['category'] = _selectedCategory;
      }
      if (_search.isNotEmpty) params['search'] = _search;
      if (_location.isNotEmpty) params['location'] = _location;

      final response = await dio.get('/api/employee/jobs/recommended/', queryParameters: params);
      final newJobs = List<Map<String, dynamic>>.from(response.data['jobs'] ?? []);

      setState(() {
        if (reset) {
          _jobs = newJobs;
        } else {
          _jobs.addAll(newJobs);
        }
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        // Handle error - show snackbar or error state
      });
    }
  }

  Future<void> _swipeJob(bool interested, String jobId) async {
    try {
      final dio = await ApiClient().authed();
      await dio.post('/api/employee/jobs/swipe/', data: {
        'job_id': jobId,
        'interested': interested,
      });

      // Move to next job
      setState(() {
        if (_currentIndex < _jobs.length - 1) {
          _currentIndex++;
        } else {
          // Load more jobs or reset
          _loadJobs(reset: true);
        }
      });
    } catch (e) {
      // Handle swipe error
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save response')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // UI implementation with job cards, swipe gestures, etc.
    return Scaffold(
      // Implementation details...
    );
  }
}
```

## 3. Application Management Module

### Backend (Django) - Job Applications
```python
# recruitment/views.py - Job Applications
@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def employee_jobs_swipe(request):
    """
    Handle employee job swipe (apply or pass)
    """
    job_id = request.data.get('job_id')
    interested = request.data.get('interested', False)

    if not job_id:
        return Response({'error': 'job_id is required'}, status=400)

    try:
        job = Job.objects.get(pk=job_id, is_open=True)
    except Job.DoesNotExist:
        return Response({'error': 'Job not found'}, status=404)

    if interested:
        # Create application if it doesn't exist
        application, created = Application.objects.get_or_create(
            job=job,
            candidate=request.user,
            defaults={'status': 'pending'}
        )

        if created:
            # Create notification for employer
            Notification.objects.create(
                user=job.employer,
                message=f'New application received for {job.title}',
                type='application',
                action_url=f'/jobs/{job.id}/applicants/'
            )

    return Response({'message': 'ok'})

@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def employee_applications_list(request):
    """
    Get employee's application history
    """
    applications = Application.objects.filter(
        candidate=request.user
    ).select_related('job__employer').order_by('-created_at')

    data = []
    for app in applications:
        data.append({
            'id': app.id,
            'job_id': app.job_id,
            'job_title': app.job.title,
            'company': app.job.employer.get_full_name() or app.job.employer.username,
            'status': app.status,
            'applied_date': app.created_at,
            'location': app.job.location,
            'job_type': 'Full-time',
            'interview_date': getattr(
                app.interviews.order_by('scheduled_at').first(),
                'scheduled_at',
                None
            ),
        })

    return Response({'applications': data})
```

### Backend (Django) - Employer Application Management
```python
# recruitment/views.py - Employer Application Management
@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def job_applicants(request, job_id):
    """
    Get all applicants for a specific job
    """
    try:
        job = Job.objects.get(pk=job_id, employer=request.user)
    except Job.DoesNotExist:
        return Response({'error': 'Job not found'}, status=404)

    applications = Application.objects.filter(
        job=job
    ).select_related('candidate__candidate_profile')

    data = []
    for app in applications:
        profile = app.candidate.candidate_profile
        data.append({
            'id': app.id,
            'name': app.candidate.get_full_name() or app.candidate.get_username(),
            'email': app.candidate.email,
            'summary': (profile.summary if profile else ''),
            'experience': profile.skills if profile else [],
            'status': app.status,
            'applied_date': app.created_at,
        })

    return Response({'applicants': data})

@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def job_applicants_swipe(request, job_id):
    """
    Update application status (shortlist, reject, interview)
    """
    app_id = request.data.get('applicant_id')
    advance = request.data.get('advance', False)  # true for interview, false for reject

    try:
        application = Application.objects.get(
            pk=app_id,
            job_id=job_id,
            job__employer=request.user
        )
    except Application.DoesNotExist:
        return Response({'error': 'Application not found'}, status=404)

    # Update status
    if advance:
        application.status = 'interview'
        # Create interview record
        Interview.objects.create(
            application=application,
            scheduled_at=timezone.now() + timedelta(days=7)  # Default to 1 week later
        )
    else:
        application.status = 'rejected'

    application.save()

    # Create notification for candidate
    Notification.objects.create(
        user=application.candidate,
        message=f'Your application for {application.job.title} has been {application.status}',
        type='application_update',
        action_url=f'/applications/{application.id}/'
    )

    return Response({
        'message': 'updated',
        'status': application.status
    })
```

## 4. Profile Management Module

### Backend (Django) - Candidate Profile
```python
# recruitment/views.py - Profile Management
@api_view(['GET', 'PUT'])
@permission_classes([permissions.IsAuthenticated])
def candidate_profile(request):
    """
    Get or update candidate profile
    """
    profile, created = CandidateProfile.objects.get_or_create(
        user=request.user,
        defaults={}
    )

    if request.method == 'GET':
        serializer = CandidateProfileSerializer(profile)
        return Response(serializer.data)

    else:  # PUT
        serializer = CandidateProfileSerializer(profile, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()

            # Trigger job recommendation update (could be async)
            # update_candidate_recommendations(request.user)

            return Response(serializer.data)
        return Response(serializer.errors, status=400)
```

### Frontend (Flutter) - Profile Screen
```dart
// lib/features/profile/presentation/screens/profile_screen.dart
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  // Form controllers
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _summaryController = TextEditingController();
  List<Map<String, dynamic>> _skills = [];
  List<Map<String, dynamic>> _education = [];
  List<Map<String, dynamic>> _experience = [];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    try {
      final dio = await ApiClient().authed();
      final response = await dio.get('/api/candidate/profile/');
      final data = response.data as Map<String, dynamic>;

      setState(() {
        _titleController.text = data['title'] ?? '';
        _locationController.text = data['location'] ?? '';
        _summaryController.text = data['summary'] ?? '';
        _skills = List<Map<String, dynamic>>.from(data['skills'] ?? []);
        _education = List<Map<String, dynamic>>.from(data['education'] ?? []);
        _experience = List<Map<String, dynamic>>.from(data['experience'] ?? []);
      });
    } catch (e) {
      // Handle error
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final dio = await ApiClient().authed();
      final data = {
        'title': _titleController.text,
        'location': _locationController.text,
        'summary': _summaryController.text,
        'skills': _skills,
        'education': _education,
        'experience': _experience,
      };

      await dio.put('/api/candidate/profile/', data: data);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update profile')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Professional Title'),
              validator: (value) => value?.isEmpty ?? true ? 'Title is required' : null,
            ),
            // Add other form fields...
            ElevatedButton(
              onPressed: _saveProfile,
              child: const Text('Save Profile'),
            ),
          ],
        ),
      ),
    );
  }
}
```

## 5. Notification System Module

### Backend (Django) - Notification Management
```python
# recruitment/views.py - Notification System
@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def notifications_list(request):
    """
    Get user's notifications
    """
    notifications = Notification.objects.filter(
        user=request.user
    ).order_by('-created_at')

    serializer = NotificationSerializer(notifications, many=True)
    return Response({'notifications': serializer.data})

@api_view(['PATCH'])
@permission_classes([permissions.IsAuthenticated])
def notifications_mark_read(request, notification_id):
    """
    Mark specific notification as read
    """
    try:
        notification = Notification.objects.get(
            pk=notification_id,
            user=request.user
        )
    except Notification.DoesNotExist:
        return Response({'error': 'Notification not found'}, status=404)

    notification.read = True
    notification.save(update_fields=['read'])
    return Response({'message': 'read'})

@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def notifications_mark_all_read(request):
    """
    Mark all user's notifications as read
    """
    Notification.objects.filter(
        user=request.user,
        read=False
    ).update(read=True)

    return Response({'message': 'all_read'})
```

### Frontend (Flutter) - Notification Screen
```dart
// lib/features/notifications/presentation/screens/notifications_screen.dart
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _loading = true);
    try {
      final dio = await ApiClient().authed();
      final response = await dio.get('/api/notifications/');
      setState(() {
        _notifications = List<Map<String, dynamic>>.from(response.data['notifications'] ?? []);
      });
    } catch (e) {
      // Handle error
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      final dio = await ApiClient().authed();
      await dio.patch('/api/notifications/$notificationId/read/');

      setState(() {
        final index = _notifications.indexWhere((n) => n['id'].toString() == notificationId);
        if (index != -1) {
          _notifications[index]['read'] = true;
        }
      });
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final dio = await ApiClient().authed();
      await dio.post('/api/notifications/mark-all-read/');

      setState(() {
        for (var notification in _notifications) {
          notification['read'] = true;
        }
      });
    } catch (e) {
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: _markAllAsRead,
            child: const Text('Mark All Read'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? const Center(child: Text('No notifications'))
              : ListView.builder(
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final notification = _notifications[index];
                    return ListTile(
                      title: Text(notification['message']),
                      subtitle: Text(notification['created_at']),
                      trailing: notification['read']
                          ? const Icon(Icons.check, color: Colors.green)
                          : IconButton(
                              icon: const Icon(Icons.mark_email_read),
                              onPressed: () => _markAsRead(notification['id'].toString()),
                            ),
                      onTap: () {
                        // Handle notification tap - navigate to relevant screen
                      },
                    );
                  },
                ),
    );
  }
}
```

## Module Summaries

### 1. Authentication Module
**Purpose**: Handles user registration, login, logout, and password management
**Key Functions**: JWT token generation/validation, user credential verification, session management
**Security**: Password hashing, token expiration, role-based access control

### 2. Job Management Module
**Purpose**: Manages job postings and job discovery for employees
**Key Functions**: CRUD operations for jobs, job search/filtering, job recommendations
**Features**: Category filtering, location search, pagination, employer job management

### 3. Application Management Module
**Purpose**: Handles job applications from submission to status updates
**Key Functions**: Application creation, status tracking, employer review process
**Workflow**: Apply → Review → Shortlist/Reject → Interview scheduling

### 4. Profile Management Module
**Purpose**: Manages user profiles for both candidates and employers
**Key Functions**: Profile creation/updates, skills/experience tracking, resume uploads
**Integration**: Affects job recommendations and candidate visibility

### 5. Notification System Module
**Purpose**: Keeps users informed about important events and updates
**Key Functions**: Notification creation, delivery, read status tracking
**Types**: Application updates, interview scheduling, system announcements

These pseudo code implementations provide a comprehensive overview of how each module works within the Mabasa job platform, showing the interaction between frontend and backend components.