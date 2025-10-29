from django.urls import path
from . import views

urlpatterns = [
    path('jobs/', views.jobs),
    path('jobs/<int:job_id>/', views.job_detail),
    path('jobs/<int:job_id>/applicants/', views.job_applicants),
    path('jobs/<int:job_id>/applicants/swipe/', views.job_applicants_swipe),
    path('candidates/recommended/', views.candidates_recommended),
    path('candidates/swipe/', views.candidates_swipe),
    path('shortlist/', views.shortlist),
    path('shortlist/<int:candidate_id>/', views.shortlist_remove),
    path('interviews/', views.interviews),
    path('interviews/schedule/', views.interviews_schedule),
    path('interviews/<int:interview_id>/', views.interview_detail),
    # notifications
    path('notifications/', views.notifications_list),
    path('notifications/<int:notification_id>/read/', views.notifications_mark_read),
    path('notifications/mark-all-read/', views.notifications_mark_all_read),
    path('notifications/<int:notification_id>/', views.notifications_delete),
]


