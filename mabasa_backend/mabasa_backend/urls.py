from django.contrib import admin
from django.urls import path, include
from django.http import JsonResponse
from recruitment import views as recruitment_views

def api_root(request):
	return JsonResponse({
		'message': 'Mabasa API is running',
		'endpoints': {
			'auth': '/api/auth/',
			'admin': '/admin/',
		}
	})

urlpatterns = [
	path('', api_root, name='api_root'),
	path('admin/', admin.site.urls),
	path('api/auth/', include('accounts.urls')),
    path('api/employer/', include('recruitment.urls')),
    path('api/employee/', include('recruitment.employee_urls')),
    # shared notifications (used by employee NotificationsScreen)
    path('api/notifications/', recruitment_views.notifications_list),
    path('api/notifications/<int:notification_id>/read/', recruitment_views.notifications_mark_read),
    path('api/notifications/mark-all-read/', recruitment_views.notifications_mark_all_read),
    path('api/notifications/<int:notification_id>/', recruitment_views.notifications_delete),
]
