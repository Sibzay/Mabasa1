# Database Schema Relationships

```mermaid
erDiagram
    User ||--o{ Job : posts
    User ||--o{ Application : applies
    User ||--o{ CandidateProfile : has
    User ||--o{ Notification : receives

    Job ||--o{ Application : receives
    Application ||--o{ Interview : leads_to

    Job {
        int id PK
        int employer_id FK
        string title
        string location
        text description
        string category
        json requirements
        string salary_range
        boolean is_open
        datetime created_at
    }

    Application {
        int id PK
        int job_id FK
        int candidate_id FK
        string status
        datetime created_at
        text feedback_notes
    }

    CandidateProfile {
        int id PK
        int user_id FK
        string title
        string location
        text summary
        json skills
        json education
        json experience
        int years_experience
    }

    Interview {
        int id PK
        int application_id FK
        datetime scheduled_at
        string status
    }

    Notification {
        int id PK
        int user_id FK
        text message
        string type
        string action_url
        boolean read
        datetime created_at
    }