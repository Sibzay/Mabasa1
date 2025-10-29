from django.urls import path
from . import views

urlpatterns = [
    # employee endpoints
    path('jobs/recommended/', views.employee_jobs_recommended),
    path('jobs/swipe/', views.employee_jobs_swipe),
    path('applications/', views.employee_applications_list),
    path('applications/<int:application_id>/', views.employee_application_delete),
    path('applications/reapply/', views.employee_application_reapply),
]