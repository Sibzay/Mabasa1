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
    # notifications
    path('notifications/', views.notifications_list),
    path('notifications/<int:notification_id>/read/', views.notifications_mark_read),
    path('notifications/mark-all-read/', views.notifications_mark_all_read),
    path('notifications/<int:notification_id>/', views.notifications_delete),
    # employee endpoints
    path('employee/jobs/recommended/', views.employee_jobs_recommended),
    path('employee/jobs/swipe/', views.employee_jobs_swipe),
    path('employee/applications/', views.employee_applications_list),
    path('employee/applications/<int:application_id>/', views.employee_application_delete),
    path('employee/applications/reapply/', views.employee_application_reapply),
]


