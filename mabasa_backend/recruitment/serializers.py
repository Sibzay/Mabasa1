from rest_framework import serializers
from .models import Job, Application, Interview, CandidateProfile, Notification


class JobSerializer(serializers.ModelSerializer):
    class Meta:
        model = Job
        fields = [
            'id', 'title', 'location', 'description', 'category', 'requirements', 'salary_range',
            'required_certifications', 'education_level', 'salary_amount', 'salary_currency',
            'duties_responsibilities', 'expected_hours', 'work_type', 'work_days', 'created_at',
            'is_open', 'closing_date'
        ]


class CandidateProfileSerializer(serializers.ModelSerializer):
    name = serializers.SerializerMethodField()
    email = serializers.SerializerMethodField()

    class Meta:
        model = CandidateProfile
        fields = ['name', 'email', 'title', 'location', 'summary', 'skills', 'resume_url', 
                 'education', 'experience', 'years_experience']

    def get_name(self, obj):
        return obj.user.get_full_name() or obj.user.get_username()

    def get_email(self, obj):
        return obj.user.email


class ApplicationSerializer(serializers.ModelSerializer):
    candidate = CandidateProfileSerializer(source='candidate.candidate_profile')
    job = JobSerializer()

    class Meta:
        model = Application
        fields = ['id', 'status', 'created_at', 'feedback_notes', 'candidate', 'job']


class InterviewSerializer(serializers.ModelSerializer):
    candidate_name = serializers.SerializerMethodField()
    job_title = serializers.SerializerMethodField()
    application_id = serializers.SerializerMethodField()

    class Meta:
        model = Interview
        fields = ['id', 'scheduled_at', 'status', 'candidate_name', 'job_title', 'application_id', 'notes', 'location', 'created_at', 'updated_at']

    def get_candidate_name(self, obj):
        user = obj.application.candidate
        return user.get_full_name() or user.get_username()

    def get_job_title(self, obj):
        return obj.application.job.title

    def get_application_id(self, obj):
        return obj.application.id


class NotificationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Notification
        fields = ['id', 'message', 'type', 'action_url', 'read', 'created_at']


