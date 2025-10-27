# Class Diagram - Mabasa Job Platform

```mermaid
classDiagram
    %% Backend Models (Django)
    class User {
        +int id
        +string username
        +string email
        +string first_name
        +string last_name
        +string role (employee/employer)
        +DateTime date_joined
        +get_full_name()
        +get_username()
    }

    class Job {
        +int id
        +User employer
        +string title
        +string location
        +text description
        +string category
        +JSONField requirements
        +string salary_range
        +boolean is_open
        +DateTime created_at
        +__str__()
    }

    class CandidateProfile {
        +int id
        +User user
        +string title
        +string location
        +text summary
        +JSONField skills
        +JSONField education
        +JSONField experience
        +int years_experience
        +__str__()
    }

    class Application {
        +int id
        +Job job
        +User candidate
        +string status
        +DateTime created_at
        +text feedback_notes
    }

    class Interview {
        +int id
        +Application application
        +DateTime scheduled_at
        +string status
    }

    class Notification {
        +int id
        +User user
        +text message
        +string type
        +string action_url
        +boolean read
        +DateTime created_at
    }

    %% Frontend Classes (Flutter)
    class ApiClient {
        -Dio _dio
        +ApiClient()
        +Future~Dio~ authed()
        +Dio get raw
    }

    class AuthService {
        -ApiClient _client
        +Future~Map~ login(usernameOrEmail, password)
        +Future~Map~ register(data)
        +Future~Map~ me()
        +Future~void~ logout()
        +Future~void~ forgotPassword(email)
        -Future~void~ _saveTokens(data)
    }

    class AuthProvider {
        +FutureProvider~Map?~ authStateProvider
    }

    class JobSwipeScreen {
        -List~Map~ _jobs
        -bool _loading
        -int _currentIndex
        -String? _error
        +JobSwipeScreen(data)
        +build(context)
        -_loadJobs(reset)
        -_swipeJob(interested, jobId)
    }

    class AppRouter {
        +GoRouter router
    }

    %% Relationships
    User ||--o{ Job : posts
    User ||--o{ Application : applies
    User ||--o{ CandidateProfile : has
    User ||--o{ Notification : receives

    Job ||--o{ Application : receives
    Application ||--o{ Interview : leads_to

    %% Service Relationships
    AuthService --> ApiClient : uses
    AuthProvider --> AuthService : uses
    JobSwipeScreen --> ApiClient : uses

    %% Screen Relationships
    AppRouter --> JobSwipeScreen : routes to
    AppRouter --> AuthProvider : depends on