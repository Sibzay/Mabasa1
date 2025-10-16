from django.urls import path
from django.http import JsonResponse


def list_jobs(request):
    return JsonResponse({
        'jobs': [
            { 'id': 1, 'title': 'Flutter Developer', 'location': 'Harare', 'description': 'Build mobile apps' },
            { 'id': 2, 'title': 'Backend Engineer', 'location': 'Bulawayo', 'description': 'Build APIs' },
        ]
    })


def create_job(request):
    return JsonResponse({ 'message': 'created' })


def update_job(request, job_id: int):
    return JsonResponse({ 'message': 'updated', 'id': job_id })


def delete_job(request, job_id: int):
    return JsonResponse({ 'message': 'deleted', 'id': job_id })


def candidates_feed(request):
    return JsonResponse({
        'candidates': [
            { 'id': 'c1', 'name': 'Tariro Moyo', 'title': 'Flutter Developer', 'location': 'Harare', 'experience': '3 years', 'skills': ['Dart','Flutter'], 'bio': 'Passionate mobile dev' },
            { 'id': 'c2', 'name': 'Kuda Ncube', 'title': 'Backend Engineer', 'location': 'Bulawayo', 'experience': '5 years', 'skills': ['Python','Django'], 'bio': 'API-first developer' },
        ]
    })


def candidates_swipe(request):
    return JsonResponse({ 'message': 'saved' })


def shortlist_list(request):
    return JsonResponse({
        'candidates': [
            { 'id': 'c2', 'name': 'Kuda Ncube', 'title': 'Backend Engineer' },
        ]
    })


def shortlist_delete(request, candidate_id: str):
    return JsonResponse({ 'message': 'removed', 'id': candidate_id })


def interviews_list(request):
    return JsonResponse({
        'interviews': [
            { 'id': 1, 'candidate_name': 'Kuda Ncube', 'datetime': '2025-10-20T10:00:00Z', 'status': 'scheduled' },
        ]
    })


def interviews_schedule(request):
    return JsonResponse({ 'message': 'scheduled' })


urlpatterns = [
    path('jobs/', list_jobs),
    path('jobs/<int:job_id>/', delete_job),
    path('jobs/<int:job_id>/', update_job),
    path('jobs/', create_job),
    path('candidates/recommended/', candidates_feed),
    path('candidates/swipe/', candidates_swipe),
    path('shortlist/', shortlist_list),
    path('shortlist/<str:candidate_id>/', shortlist_delete),
    path('interviews/', interviews_list),
    path('interviews/schedule/', interviews_schedule),
]


