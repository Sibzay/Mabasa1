from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework import permissions, status
from django.shortcuts import get_object_or_404
from .models import Job, Application, CandidateProfile, Interview, Notification
from .serializers import JobSerializer, ApplicationSerializer, InterviewSerializer, CandidateProfileSerializer, NotificationSerializer


@api_view(['GET', 'POST'])
@permission_classes([permissions.IsAuthenticated])
def jobs(request):
    if request.method == 'GET':
        qs = Job.objects.filter(employer=request.user).order_by('-created_at')
        category = request.query_params.get('category')
        if category and category != 'All':
            qs = qs.filter(category=category)
        return Response({ 'jobs': JobSerializer(qs, many=True).data })
    else:
        serializer = JobSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        job = serializer.save(employer=request.user)
        return Response(JobSerializer(job).data, status=status.HTTP_201_CREATED)


@api_view(['PUT', 'DELETE'])
@permission_classes([permissions.IsAuthenticated])
def job_detail(request, job_id: int):
    job = get_object_or_404(Job, pk=job_id, employer=request.user)
    if request.method == 'PUT':
        serializer = JobSerializer(job, data=request.data, partial=False)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response(serializer.data)
    else:
        job.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def candidates_recommended(request):
    print(f"Candidates recommended called by user: {request.user}")
    qs = CandidateProfile.objects.select_related('user')
    category = request.query_params.get('category')
    print(f"Category filter: {category}")
    if category and category != 'All':
        qs = qs.filter(title__icontains=category)
    data = CandidateProfileSerializer(qs[:20], many=True).data
    print(f"QuerySet count: {qs.count()}, serialized data count: {len(data)}")
    # Attach ids for swipe actions
    for i, c in enumerate(data):
        c['id'] = qs[i].user.id
    print(f"Final candidates data: {data}")
    return Response({ 'candidates': data })


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def candidates_swipe(request):
    # Here you can create shortlist entries etc.
    return Response({ 'message': 'saved' })


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def shortlist(request):
    apps = Application.objects.filter(job__employer=request.user, status='shortlisted').select_related('candidate__candidate_profile')
    # Flatten to candidate entries
    candidates = []
    for app in apps:
        prof = app.candidate.candidate_profile
        candidates.append({
            'id': app.candidate.id,
            'name': app.candidate.get_full_name() or app.candidate.get_username(),
            'title': prof.title if prof else '',
        })
    return Response({ 'candidates': candidates })


@api_view(['DELETE'])
@permission_classes([permissions.IsAuthenticated])
def shortlist_remove(request, candidate_id: int):
    Application.objects.filter(job__employer=request.user, candidate_id=candidate_id, status='shortlisted').update(status='rejected')
    return Response(status=status.HTTP_204_NO_CONTENT)


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def interviews(request):
    itvs = Interview.objects.filter(application__job__employer=request.user).select_related('application__candidate')
    return Response({ 'interviews': InterviewSerializer(itvs, many=True).data })


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def interviews_schedule(request):
    # Minimal stub – requires an application; in UI we schedule by candidate id only
    return Response({ 'message': 'scheduled' })


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def job_applicants(request, job_id: int):
    apps = Application.objects.filter(job_id=job_id, job__employer=request.user).select_related('candidate__candidate_profile')
    data = []
    for app in apps:
        prof = app.candidate.candidate_profile
        data.append({
            'id': app.id,
            'name': app.candidate.get_full_name() or app.candidate.get_username(),
            'email': app.candidate.email,
            'summary': (prof.summary if prof else ''),
            'experience': prof.skills if prof else [],
        })
    return Response({ 'applicants': data })


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def job_applicants_swipe(request, job_id: int):
    app_id = request.data.get('applicant_id')
    advance = bool(request.data.get('advance'))
    app = get_object_or_404(Application, pk=app_id, job_id=job_id, job__employer=request.user)
    app.status = 'interview' if advance else 'rejected'
    app.save(update_fields=['status'])
    return Response({ 'message': 'updated', 'status': app.status })


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def notifications_list(request):
    qs = Notification.objects.filter(user=request.user).order_by('-created_at')
    return Response({ 'notifications': NotificationSerializer(qs, many=True).data })


@api_view(['PATCH'])
@permission_classes([permissions.IsAuthenticated])
def notifications_mark_read(request, notification_id: int):
    notif = Notification.objects.filter(pk=notification_id, user=request.user).first()
    if not notif:
        return Response(status=status.HTTP_404_NOT_FOUND)
    notif.read = True
    notif.save(update_fields=['read'])
    return Response({ 'message': 'read' })


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def notifications_mark_all_read(request):
    Notification.objects.filter(user=request.user, read=False).update(read=True)
    return Response({ 'message': 'all_read' })


@api_view(['DELETE'])
@permission_classes([permissions.IsAuthenticated])
def notifications_delete(request, notification_id: int):
    Notification.objects.filter(pk=notification_id, user=request.user).delete()
    return Response(status=status.HTTP_204_NO_CONTENT)


# Employee APIs
@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def employee_jobs_recommended(request):
    qs = Job.objects.all().order_by('-created_at')
    # filters
    category = request.query_params.get('category')
    search = request.query_params.get('search')
    location = request.query_params.get('location')
    try:
        page = int(request.query_params.get('page', '1'))
        page_size = int(request.query_params.get('page_size', '20'))
    except ValueError:
        page, page_size = 1, 20

    if category and category != 'All':
        qs = qs.filter(category=category)
    if search:
        qs = qs.filter(title__icontains=search)
    if location:
        qs = qs.filter(location__icontains=location)

    total = qs.count()
    start = (page - 1) * page_size
    end = start + page_size
    items = qs[start:end]

    data = []
    for j in items:
        data.append({
            'id': j.id,
            'title': j.title,
            'company': j.employer.get_full_name() or j.employer.username,
            'location': j.location,
            'salary': j.salary_range or 'Competitive',
            'description': j.description,
            'type': 'Full-time',
            'requirements': j.requirements,
        })
    return Response({ 'jobs': data, 'page': page, 'page_size': page_size, 'total': total })


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def employee_jobs_swipe(request):
    # For now, if interested -> create application; else ignore
    job_id = request.data.get('job_id')
    interested = bool(request.data.get('interested'))
    if interested and job_id:
        job = get_object_or_404(Job, pk=job_id)
        Application.objects.get_or_create(job=job, candidate=request.user)
    return Response({ 'message': 'ok' })


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def employee_applications_list(request):
    apps = Application.objects.filter(candidate=request.user).select_related('job__employer')
    data = []
    for app in apps:
        data.append({
            'id': app.id,
            'job_id': app.job_id,
            'job_title': app.job.title,
            'company': app.job.employer.get_full_name() or app.job.employer.username,
            'status': app.status,
            'applied_date': app.created_at,
            'location': app.job.location,
            'job_type': 'Full-time',
            'interview_date': getattr(app.interviews.order_by('scheduled_at').first(), 'scheduled_at', None),
        })
    return Response({ 'applications': data })


@api_view(['DELETE'])
@permission_classes([permissions.IsAuthenticated])
def employee_application_delete(request, application_id: int):
    Application.objects.filter(pk=application_id, candidate=request.user).delete()
    return Response(status=status.HTTP_204_NO_CONTENT)


@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def employee_application_reapply(request):
    job_id = request.data.get('job_id')
    job = get_object_or_404(Job, pk=job_id)
    Application.objects.get_or_create(job=job, candidate=request.user, defaults={'status': 'pending'})
    return Response({ 'message': 'reapplied' })


