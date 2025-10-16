from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model
from django.utils import timezone

from recruitment.models import Job, CandidateProfile, Application, Interview, Notification


class Command(BaseCommand):
    help = 'Seed demo data for employer/candidate flows'

    def handle(self, *args, **options):
        User = get_user_model()

        # Employer
        employer, _ = User.objects.get_or_create(
            username='employer1',
            defaults={
                'email': 'employer1@example.com',
                'role': 'employer',
            }
        )
        employer.set_password('password123')
        employer.save()

        # Candidates
        c1, _ = User.objects.get_or_create(
            username='candidate1',
            defaults={
                'email': 'candidate1@example.com',
                'role': 'employee',
                'first_name': 'Tariro',
                'last_name': 'Moyo',
            }
        )
        c1.set_password('password123')
        c1.save()

        c2, _ = User.objects.get_or_create(
            username='candidate2',
            defaults={
                'email': 'candidate2@example.com',
                'role': 'employee',
                'first_name': 'Kuda',
                'last_name': 'Ncube',
            }
        )
        c2.set_password('password123')
        c2.save()

        # Candidate Profiles
        CandidateProfile.objects.update_or_create(
            user=c1,
            defaults={
                'title': 'Flutter Developer',
                'location': 'Harare',
                'summary': 'Passionate mobile dev building clean, scalable apps.',
                'skills': ['Dart', 'Flutter', 'REST APIs'],
                'resume_url': '',
            }
        )
        CandidateProfile.objects.update_or_create(
            user=c2,
            defaults={
                'title': 'Backend Engineer',
                'location': 'Bulawayo',
                'summary': 'API-first developer focused on performance and reliability.',
                'skills': ['Python', 'Django', 'PostgreSQL'],
                'resume_url': '',
            }
        )

        # Jobs
        job1, _ = Job.objects.get_or_create(
            employer=employer,
            title='Flutter Developer',
            defaults={
                'location': 'Harare',
                'description': 'Build mobile apps',
                'category': 'ICT',
                'requirements': ['Flutter', 'Dart', 'Clean Architecture'],
                'salary_range': 'ZW$ Negotiable',
            }
        )
        job2, _ = Job.objects.get_or_create(
            employer=employer,
            title='Backend Engineer',
            defaults={
                'location': 'Bulawayo',
                'description': 'Build APIs and services',
                'category': 'ICT',
                'requirements': ['Python', 'Django', 'PostgreSQL'],
                'salary_range': 'ZW$ Negotiable',
            }
        )

        # Applications
        app1, _ = Application.objects.get_or_create(
            job=job1,
            candidate=c1,
            defaults={
                'status': 'pending',
                'feedback_notes': '',
            }
        )
        app2, _ = Application.objects.get_or_create(
            job=job2,
            candidate=c2,
            defaults={
                'status': 'shortlisted',
                'feedback_notes': 'Strong profile',
            }
        )

        # Interview for shortlisted
        Interview.objects.get_or_create(
            application=app2,
            scheduled_at=timezone.now() + timezone.timedelta(days=3),
            defaults={'status': 'scheduled'}
        )

        # Notifications
        Notification.objects.get_or_create(
            user=c1,
            message='Your application has been received.',
            defaults={'type': 'application'}
        )
        Notification.objects.get_or_create(
            user=c2,
            message='Interview scheduled in 3 days.',
            defaults={'type': 'interview'}
        )

        Notification.objects.get_or_create(
            user=employer,
            message='2 new applicants for your jobs.',
            defaults={'type': 'application'}
        )

        self.stdout.write(self.style.SUCCESS('Demo data seeded. Employer login: employer1/password123'))


