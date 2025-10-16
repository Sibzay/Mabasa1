from django.contrib.auth import get_user_model
from rest_framework import generics, permissions, status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework_simplejwt.views import TokenObtainPairView
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer

from .serializers import RegisterSerializer, UserSerializer

User = get_user_model()


class CustomTokenObtainPairSerializer(TokenObtainPairSerializer):
	@classmethod
	def get_token(cls, user):
		token = super().get_token(user)
		token['role'] = user.role
		return token

	def validate(self, attrs):
		data = super().validate(attrs)
		data['user'] = UserSerializer(self.user).data
		return data


class CustomTokenObtainPairView(TokenObtainPairView):
	serializer_class = CustomTokenObtainPairSerializer


class RegisterView(generics.CreateAPIView):
	permission_classes = [permissions.AllowAny]
	serializer_class = RegisterSerializer


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def me(request):
	return Response(UserSerializer(request.user).data)


@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def dashboard(request):
	role = request.user.role
	if role == User.ROLE_EMPLOYER:
		return Response({'message': 'Employer dashboard', 'stats': {'jobs_posted': 0, 'applicants': 0}})
	return Response({'message': 'Employee dashboard', 'stats': {'jobs_suggested': 3, 'applications': 0}})


@api_view(['POST'])
@permission_classes([permissions.AllowAny])
def forgot_password(request):
    # Accept email and respond generically to avoid user enumeration
    email = request.data.get('email')
    # If you configure email backend, trigger Django's password reset workflow here
    # from django.contrib.auth.forms import PasswordResetForm
    # PasswordResetForm({'email': email}).is_valid(); form.save(...)
    return Response(
        {"message": "If the email exists, a reset link has been sent."},
        status=status.HTTP_200_OK,
    )
