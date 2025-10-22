from django.db import models
from django.conf import settings


class JobCategory(models.TextChoices):
    ACCOUNTANCY = 'Accountancy'
    ADMINISTRATION = 'Administration'
    ICT = 'ICT'
    MANUFACTURING = 'Manufacturing'
    HR = 'HR'
    SALES = 'Sales'
    LOGISTICS = 'Logistics'


class Job(models.Model):
    WORK_TYPE_CHOICES = [
        ('office', 'In Office'),
        ('remote', 'Remote'),
        ('hybrid', 'Hybrid'),
    ]
    
    employer = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='jobs')
    title = models.CharField(max_length=200)
    location = models.CharField(max_length=120)
    description = models.TextField(blank=True)
    category = models.CharField(max_length=64, choices=[(c.value, c.value) for c in JobCategory])
    requirements = models.JSONField(default=list, blank=True)  # list of strings (skills/experience)
    salary_range = models.CharField(max_length=120, blank=True)
    # Posting lifecycle
    is_open = models.BooleanField(default=True)
    closing_date = models.DateField(null=True, blank=True)
    
    # New fields
    required_certifications = models.TextField(blank=True)
    education_level = models.CharField(max_length=100, blank=True)
    salary_amount = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    salary_currency = models.CharField(max_length=3, default='USD')
    duties_responsibilities = models.TextField(blank=True)
    expected_hours = models.CharField(max_length=50, blank=True)
    work_type = models.CharField(max_length=20, choices=WORK_TYPE_CHOICES, default='office')
    work_days = models.CharField(max_length=100, blank=True)  # e.g., "Monday-Friday"
    
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self) -> str:
        return self.title


class CandidateProfile(models.Model):
    user = models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='candidate_profile')
    title = models.CharField(max_length=200, blank=True)
    location = models.CharField(max_length=120, blank=True)
    summary = models.TextField(blank=True)
    skills = models.JSONField(default=list, blank=True)
    resume_url = models.CharField(max_length=500, blank=True)
    # Extended profile
    education = models.JSONField(default=list, blank=True)  # [{institution, qualification, start, end}]
    experience = models.JSONField(default=list, blank=True)  # [{company, role, start, end, description}]
    years_experience = models.PositiveIntegerField(default=0)

    def __str__(self) -> str:
        return self.user.get_username()


class Application(models.Model):
    STATUS_CHOICES = (
        ('pending', 'Pending'),
        ('shortlisted', 'Shortlisted'),
        ('rejected', 'Rejected'),
        ('interview', 'Interview'),
        ('accepted', 'Accepted'),
    )
    job = models.ForeignKey(Job, on_delete=models.CASCADE, related_name='applications')
    candidate = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='applications')
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    created_at = models.DateTimeField(auto_now_add=True)
    feedback_notes = models.TextField(blank=True)


class Interview(models.Model):
    application = models.ForeignKey(Application, on_delete=models.CASCADE, related_name='interviews')
    scheduled_at = models.DateTimeField()
    status = models.CharField(max_length=20, default='scheduled')


class Notification(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='notifications')
    message = models.TextField()
    type = models.CharField(max_length=32, default='general')
    action_url = models.CharField(max_length=500, blank=True)
    read = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)


