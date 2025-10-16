from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView
from .views import RegisterView, CustomTokenObtainPairView, me, dashboard, forgot_password

urlpatterns = [
	path('register/', RegisterView.as_view(), name='register'),
	path('token/', CustomTokenObtainPairView.as_view(), name='token_obtain_pair'),
	path('token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
	path('me/', me, name='me'),
	path('dashboard/', dashboard, name='dashboard'),
    path('forgot-password/', forgot_password, name='forgot_password'),
]
