# Interface Design Diagram - Mabasa Job Platform

## Overview
This interface design diagram shows the user interface structure and navigation flow of the Mabasa job application platform. It illustrates the relationships between screens, user interactions, and data flow between the frontend and backend systems.

```mermaid
graph TD
    %% Main Application Container
    subgraph "Mabasa Job App (Flutter)"
        %% Authentication Interfaces
        subgraph "Authentication Module"
            LOGIN[📱 Login Screen<br/>• Username/Email field<br/>• Password field<br/>• Login button<br/>• Register link<br/>• Forgot password link]
            REGISTER[📱 Register Screen<br/>• Username field<br/>• Email field<br/>• Password fields<br/>• Role selection (Employee/Employer)<br/>• First/Last name<br/>• Register button<br/>• Login link]
            FORGOT_PASSWORD[📱 Forgot Password Screen<br/>• Email field<br/>• Reset button<br/>• Back to login link]
        end

        %% Employee Interfaces
        subgraph "Employee/Candidate Module"
            EMPLOYEE_DASHBOARD[📱 Employee Dashboard<br/>• Welcome message<br/>• Quick stats<br/>• Navigation menu<br/>• Recent applications]
            JOB_SWIPE[📱 Job Swipe Screen<br/>• Job cards with swipe<br/>• Job details overlay<br/>• Search bar<br/>• Category filters<br/>• Location filter<br/>• Heart/Reject buttons]
            APPLICATIONS_LIST[📱 Applications Screen<br/>• Application list<br/>• Status indicators<br/>• Job details<br/>• Interview dates<br/>• Reapply options]
            EMPLOYEE_PROFILE[📱 Profile Screen<br/>• Personal info<br/>• Skills section<br/>• Education form<br/>• Experience form<br/>• Resume upload<br/>• Save/Update buttons]
        end

        %% Employer Interfaces
        subgraph "Employer Module"
            EMPLOYER_DASHBOARD[📱 Employer Dashboard<br/>• Company overview<br/>• Active jobs count<br/>• Recent applications<br/>• Interview schedule<br/>• Navigation menu]
            POST_JOB[📱 Post Job Screen<br/>• Job title field<br/>• Description textarea<br/>• Location field<br/>• Category dropdown<br/>• Salary range<br/>• Requirements list<br/>• Work type selection<br/>• Post button]
            MANAGE_JOBS[📱 Manage Jobs Screen<br/>• Job listings<br/>• Edit/Delete actions<br/>• Status indicators<br/>• Application counts<br/>• View applicants button]
            JOB_APPLICANTS[📱 Job Applicants Screen<br/>• Applicant list<br/>• Profile previews<br/>• Shortlist/Reject buttons<br/>• Interview scheduling<br/>• Application details]
            CANDIDATE_SWIPE[📱 Candidate Swipe Screen<br/>• Candidate cards<br/>• Profile summaries<br/>• Skills display<br/>• Shortlist/Next buttons<br/>• Detailed view option]
            SHORTLIST[📱 Shortlist Screen<br/>• Shortlisted candidates<br/>• Remove actions<br/>• Contact options<br/>• Interview scheduling]
            INTERVIEWS[📱 Interviews Screen<br/>• Scheduled interviews<br/>• Calendar view<br/>• Interview details<br/>• Status updates<br/>• Reschedule options]
        end

        %% Shared Interfaces
        subgraph "Shared Components"
            NOTIFICATIONS[📱 Notifications Screen<br/>• Notification list<br/>• Read/unread status<br/>• Action buttons<br/>• Mark all read<br/>• Delete options]
            SETTINGS[📱 Settings Screen<br/>• Account settings<br/>• Notification preferences<br/>• Privacy settings<br/>• Theme selection<br/>• Logout button]
        end

        %% Navigation Flow
        LOGIN --> EMPLOYEE_DASHBOARD
        LOGIN --> EMPLOYER_DASHBOARD
        REGISTER --> LOGIN
        FORGOT_PASSWORD --> LOGIN

        EMPLOYEE_DASHBOARD --> JOB_SWIPE
        EMPLOYEE_DASHBOARD --> APPLICATIONS_LIST
        EMPLOYEE_DASHBOARD --> EMPLOYEE_PROFILE
        EMPLOYEE_DASHBOARD --> NOTIFICATIONS
        EMPLOYEE_DASHBOARD --> SETTINGS

        JOB_SWIPE --> APPLICATIONS_LIST
        APPLICATIONS_LIST --> EMPLOYEE_PROFILE

        EMPLOYER_DASHBOARD --> POST_JOB
        EMPLOYER_DASHBOARD --> MANAGE_JOBS
        EMPLOYER_DASHBOARD --> CANDIDATE_SWIPE
        EMPLOYER_DASHBOARD --> SHORTLIST
        EMPLOYER_DASHBOARD --> INTERVIEWS
        EMPLOYER_DASHBOARD --> NOTIFICATIONS
        EMPLOYER_DASHBOARD --> SETTINGS

        POST_JOB --> MANAGE_JOBS
        MANAGE_JOBS --> JOB_APPLICANTS
        JOB_APPLICANTS --> SHORTLIST
        JOB_APPLICANTS --> INTERVIEWS
        CANDIDATE_SWIPE --> SHORTLIST
        SHORTLIST --> INTERVIEWS
    end

    %% Backend API Interfaces
    subgraph "Django REST API Backend"
        AUTH_API[🔧 Authentication APIs<br/>• POST /api/auth/token/<br/>• POST /api/auth/register/<br/>• GET /api/auth/me/<br/>• POST /api/auth/forgot-password/]
        EMPLOYEE_API[🔧 Employee APIs<br/>• GET /api/employee/jobs/recommended/<br/>• POST /api/employee/jobs/swipe/<br/>• GET /api/employee/applications/<br/>• PUT /api/employee/profile/]
        EMPLOYER_API[🔧 Employer APIs<br/>• GET/POST /api/employer/jobs/<br/>• GET /api/employer/jobs/{id}/applicants/<br/>• POST /api/employer/jobs/{id}/applicants/swipe/<br/>• GET /api/employer/candidates/recommended/<br/>• POST /api/employer/interviews/schedule/]
        NOTIFICATION_API[🔧 Notification APIs<br/>• GET /api/notifications/<br/>• PATCH /api/notifications/{id}/read/<br/>• POST /api/notifications/mark-all-read/]
    end

    %% External Interfaces
    subgraph "External Systems"
        FIREBASE[☁️ Firebase<br/>• Push Notifications<br/>• Cloud Messaging<br/>• Authentication]
        FILE_STORAGE[☁️ File Storage<br/>• AWS S3 / Cloudinary<br/>• Resume uploads<br/>• Profile images<br/>• Secure file access]
        EMAIL_SERVICE[📧 Email Service<br/>• Password reset emails<br/>• Application notifications<br/>• Interview confirmations]
    end

    %% Interface Connections
    LOGIN --> AUTH_API
    REGISTER --> AUTH_API
    FORGOT_PASSWORD --> AUTH_API

    JOB_SWIPE --> EMPLOYEE_API
    APPLICATIONS_LIST --> EMPLOYEE_API
    EMPLOYEE_PROFILE --> EMPLOYEE_API

    POST_JOB --> EMPLOYER_API
    MANAGE_JOBS --> EMPLOYER_API
    JOB_APPLICANTS --> EMPLOYER_API
    CANDIDATE_SWIPE --> EMPLOYER_API
    SHORTLIST --> EMPLOYER_API
    INTERVIEWS --> EMPLOYER_API

    NOTIFICATIONS --> NOTIFICATION_API

    %% External Connections
    NOTIFICATION_API --> FIREBASE
    EMPLOYEE_PROFILE --> FILE_STORAGE
    FORGOT_PASSWORD --> EMAIL_SERVICE
    INTERVIEWS --> EMAIL_SERVICE

    %% Data Flow Indicators
    AUTH_API -.-> |JWT Tokens| LOGIN
    EMPLOYEE_API -.-> |Job Data| JOB_SWIPE
    EMPLOYER_API -.-> |Application Data| JOB_APPLICANTS
    NOTIFICATION_API -.-> |Notification Data| NOTIFICATIONS
    FILE_STORAGE -.-> |File URLs| EMPLOYEE_PROFILE
    FIREBASE -.-> |Push Messages| NOTIFICATIONS
```

## Interface Design Specifications

### Screen Structure Patterns

#### 1. Authentication Screens
- **Header**: App logo and title
- **Form Fields**: Properly labeled input fields with validation
- **Action Buttons**: Primary CTA buttons with loading states
- **Links**: Secondary navigation to other auth screens
- **Error Handling**: Inline validation and error messages

#### 2. List Screens (Jobs, Applications, Candidates)
- **Search/Filter Bar**: At top with search input and filter options
- **List Items**: Card-based layout with key information
- **Pagination**: Load more functionality for large datasets
- **Empty States**: Helpful messages when no data available
- **Pull to Refresh**: For updating content

#### 3. Detail Screens (Job Details, Profile)
- **Hero Section**: Key information prominently displayed
- **Tabbed Content**: Organized information sections
- **Action Buttons**: Context-appropriate actions (Apply, Edit, etc.)
- **Related Items**: Suggestions or related content

#### 4. Form Screens (Post Job, Edit Profile)
- **Progressive Disclosure**: Step-by-step form completion
- **Field Validation**: Real-time validation feedback
- **Save States**: Draft saving and confirmation dialogs
- **Help Text**: Contextual guidance for complex fields

### Navigation Patterns

#### Bottom Navigation (Employee)
- **Jobs**: Job swipe interface
- **Applications**: Application tracking
- **Profile**: Personal profile management
- **Notifications**: Notification center

#### Drawer Navigation (Employer)
- **Dashboard**: Overview and stats
- **Jobs**: Job management
- **Candidates**: Candidate discovery
- **Interviews**: Interview scheduling
- **Settings**: Account settings

### Data Input/Output Interfaces

#### Input Interfaces
- **Text Fields**: Single line, multi-line, with character limits
- **Dropdowns**: Category selections, predefined options
- **Checkboxes/Radio Buttons**: Multiple/single selections
- **File Uploads**: Resume, profile images with drag-drop
- **Date/Time Pickers**: Interview scheduling, application deadlines

#### Output Interfaces
- **Cards**: Job listings, candidate profiles, application status
- **Lists**: Notifications, application history, job postings
- **Charts/Graphs**: Dashboard statistics (future enhancement)
- **Status Indicators**: Application status, job posting status
- **Progress Bars**: Profile completion, application progress

### Error Handling Interfaces
- **Toast Messages**: Brief success/error notifications
- **Dialog Boxes**: Confirmation dialogs, error details
- **Inline Validation**: Field-level error messages
- **Empty States**: Helpful guidance when no content
- **Loading States**: Skeletons, spinners, progress indicators

### Responsive Design Considerations
- **Mobile-First**: Optimized for mobile devices
- **Tablet Support**: Adaptive layouts for larger screens
- **Keyboard Navigation**: Accessibility support
- **Touch Targets**: Minimum 44px touch targets
- **Readable Fonts**: Minimum 16px font sizes

This interface design diagram provides a comprehensive view of how users interact with the Mabasa platform, showing the relationships between screens, data flow, and external system integrations.