# Mabasa Job Application Platform - Data Flow Diagram

## Overview
This document provides a comprehensive data flow diagram for the Mabasa job application platform, which consists of a Flutter mobile app (MabasaFlutter) and a Django REST API backend (mabasa_backend). The platform supports two main user roles: Employers and Employees (Candidates).

## Architecture Components

### Frontend (Flutter App)
- **Authentication Module**: Login, registration, password reset
- **Employee Features**: Job browsing/swipe, applications, profile management
- **Employer Features**: Job posting, candidate management, interviews, shortlisting
- **Core Services**: API client, authentication service, notification service

### Backend (Django REST API)
- **Authentication App**: User management, JWT tokens
- **Recruitment App**: Jobs, applications, candidates, interviews, notifications
- **Database**: SQLite (development), PostgreSQL (production)

### External Systems
- **Firebase**: Push notifications, authentication (optional)
- **File Storage**: Resume uploads, profile images
- **Email Service**: Password reset, notifications

## Data Flow Diagrams

### 1. User Authentication Flow

```mermaid
graph TD
    A[User Opens App] --> B{Token Exists?}
    B -->|Yes| C[Validate Token]
    B -->|No| D[Login/Register Screen]

    C -->|Valid| E[Authenticated State]
    C -->|Invalid| D

    D --> F[Enter Credentials]
    F --> G[API Call: /api/auth/token/ or /api/auth/register/]
    G --> H{API Response}
    H -->|Success| I[Save Tokens to SharedPreferences]
    H -->|Error| J[Show Error Message]

    I --> E
    E --> K[Access Protected Routes]
```

### 2. Job Posting Flow (Employer)

```mermaid
graph TD
    A[Employer Dashboard] --> B[Create Job Form]
    B --> C[Fill Job Details]
    C --> D[API Call: POST /api/employer/jobs/]
    D --> E{API Response}
    E -->|Success| F[Job Created in Database]
    E -->|Error| G[Show Validation Errors]

    F --> H[Job Listed for Employees]
    H --> I[Employees Can Browse/Swipe]
```

### 3. Job Application Flow (Employee)

```mermaid
graph TD
    A[Employee Job Swipe] --> B[View Job Details]
    B --> C{Swipe Decision}
    C -->|Interested| D[API Call: POST /api/employer/employee/jobs/swipe/]
    C -->|Not Interested| E[Move to Next Job]

    D --> F{API Response}
    F -->|Success| G[Application Created]
    F -->|Error| H[Show Error]

    G --> I[Application Status: Pending]
    I --> J[Employer Can View Applications]
```

### 4. Application Management Flow (Employer)

```mermaid
graph TD
    A[Employer Views Job Applications] --> B[API Call: GET /api/employer/jobs/{job_id}/applicants/]
    B --> C[Display Candidate List]
    C --> D[Select Candidate]
    D --> E{Action}
    E -->|Shortlist| F[API Call: POST /api/employer/jobs/{job_id}/applicants/swipe/]
    E -->|Reject| G[Update Status to Rejected]
    E -->|Interview| H[Schedule Interview]

    F --> I[Status: Shortlisted]
    G --> J[Status: Rejected]
    H --> K[Create Interview Record]
```

### 5. Interview Scheduling Flow

```mermaid
graph TD
    A[Employer Schedules Interview] --> B[Select Date/Time]
    B --> C[API Call: POST /api/employer/interviews/schedule/]
    C --> D{API Response}
    D -->|Success| E[Interview Created]
    D -->|Error| F[Show Error]

    E --> G[Notification Sent to Candidate]
    G --> H[Candidate Views in Dashboard]
```

### 6. Notification System Flow

```mermaid
graph TD
    A[Event Occurs] --> B{Event Type}
    B -->|Application Received| C[Create Notification Record]
    B -->|Interview Scheduled| D[Create Notification Record]
    B -->|Status Update| E[Create Notification Record]

    C --> F[API Call: POST /api/notifications/]
    D --> F
    E --> F

    F --> G[Store in Database]
    G --> H[Push Notification to Device]
    H --> I[User Views in App]
    I --> J[Mark as Read: PATCH /api/notifications/{id}/read/]
```

### 7. Profile Management Flow

```mermaid
graph TD
    A[User Profile Screen] --> B{User Role}
    B -->|Employee| C[Candidate Profile Form]
    B -->|Employer| D[Employer Profile Form]

    C --> E[Update Skills/Education/Experience]
    D --> F[Update Company Info]

    E --> G[API Call: PUT /api/candidate/profile/]
    F --> H[API Call: PUT /api/employer/profile/]

    G --> I{API Response}
    H --> I

    I -->|Success| J[Update Database]
    I -->|Error| K[Show Validation Errors]

    J --> L[Profile Updated]
    L --> M[Sync with Job Recommendations]
    M --> N[Update Candidate Visibility]
```

## Database Schema Relationships

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
```

## API Endpoints Summary

### Authentication
- `POST /api/auth/token/` - Login
- `POST /api/auth/register/` - Register
- `GET /api/auth/me/` - Get current user
- `POST /api/auth/forgot-password/` - Password reset

### Jobs (Employer)
- `GET/POST /api/employer/jobs/` - List/Create jobs
- `PUT/DELETE /api/employer/jobs/{id}/` - Update/Delete job
- `GET /api/employer/jobs/{id}/applicants/` - View applicants
- `POST /api/employer/jobs/{id}/applicants/swipe/` - Update application status

### Candidates (Employer)
- `GET /api/employer/candidates/recommended/` - Browse candidates
- `POST /api/employer/candidates/swipe/` - Shortlist candidate
- `GET /api/employer/shortlist/` - View shortlisted candidates
- `DELETE /api/employer/shortlist/{id}/` - Remove from shortlist

### Interviews (Employer)
- `GET /api/employer/interviews/` - List interviews
- `POST /api/employer/interviews/schedule/` - Schedule interview

### Jobs (Employee)
- `GET /api/employer/employee/jobs/recommended/` - Browse jobs
- `POST /api/employer/employee/jobs/swipe/` - Apply to job
- `GET /api/employer/employee/applications/` - View applications
- `DELETE /api/employer/employee/applications/{id}/` - Delete application
- `POST /api/employer/employee/applications/reapply/` - Reapply to job

### Notifications
- `GET /api/notifications/` - List notifications
- `PATCH /api/notifications/{id}/read/` - Mark as read
- `DELETE /api/notifications/{id}/` - Delete notification
- `POST /api/notifications/mark-all-read/` - Mark all as read

## Data Storage and Caching

### Client-Side Storage
- **SharedPreferences**: JWT tokens, user role, basic settings
- **Local Database**: Job cache, offline applications (future feature)
- **Image Cache**: Profile pictures, company logos
- **Offline Queue**: Failed requests for retry when online

### Server-Side Storage
- **Primary Database**: SQLite (dev) / PostgreSQL (prod) - All application data
- **File Storage**: AWS S3 / Cloudinary for resume uploads, profile images
- **Cache Layer**: Redis for session data, API response caching, user sessions
- **Search Index**: Elasticsearch for job/candidate search functionality

### Caching Strategy
- **API Response Cache**: 5-15 minute TTL for job listings, candidate profiles
- **Static Assets**: CDN caching for images, CSS, JS files
- **Database Query Cache**: Redis caching for frequently accessed data
- **Session Cache**: User authentication state, preferences

## Security Considerations

### Authentication & Authorization
- JWT tokens with refresh mechanism and expiration
- Role-based access control (Employee vs Employer)
- Token validation on all protected endpoints
- Multi-factor authentication (future enhancement)
- Session management with secure cookies

### Data Protection
- Password hashing using bcrypt/PBKDF2
- HTTPS/TLS 1.3 for all API communications
- Input validation and sanitization on all endpoints
- SQL injection prevention through Django ORM
- XSS protection with Content Security Policy
- CSRF protection on state-changing operations

### Privacy & Compliance
- User data encryption at rest using database encryption
- GDPR compliance for EU users (data portability, right to erasure)
- Secure file upload handling with virus scanning
- Data retention policies for deleted accounts
- Audit logging for sensitive operations

### Network Security
- Rate limiting on API endpoints
- IP-based blocking for suspicious activity
- API key authentication for mobile app
- CORS configuration for cross-origin requests
- Security headers (HSTS, X-Frame-Options, etc.)

## Performance Optimizations

### Database
- Indexing on frequently queried fields
- Pagination for large result sets
- Select related queries to minimize N+1 problems

### API
- Response caching
- Database query optimization
- Background job processing for heavy operations

### Mobile App
- Lazy loading of job lists
- Image caching
- Offline capability for critical features

## Monitoring and Logging

### Backend
- API request/response logging
- Error tracking and alerting
- Performance monitoring
- Database query monitoring

### Frontend
- Crash reporting
- User analytics
- Performance metrics
- Network request monitoring

This data flow diagram provides a comprehensive overview of how data moves through the Mabasa platform, from user interactions to database persistence and back to the user interface.