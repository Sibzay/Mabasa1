from django.contrib.auth.models import AbstractUser
from django.db import models


class User(AbstractUser):
	ROLE_EMPLOYEE = 'employee'
	ROLE_EMPLOYER = 'employer'
	ROLE_CHOICES = [
		(ROLE_EMPLOYEE, 'Employee'),
		(ROLE_EMPLOYER, 'Employer'),
	]

	role = models.CharField(max_length=20, choices=ROLE_CHOICES, default=ROLE_EMPLOYEE)

	def __str__(self) -> str:
		return f"{self.username} ({self.role})"
