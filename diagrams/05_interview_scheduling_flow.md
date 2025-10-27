# 5. Interview Scheduling Flow

```mermaid
graph TD
    A[Employer Schedules Interview] --> B[Select Date/Time]
    B --> C[API Call: POST /api/employer/interviews/schedule/]
    C --> D{API Response}
    D -->|Success| E[Interview Created]
    D -->|Error| F[Show Error]

    E --> G[Notification Sent to Candidate]
    G --> H[Candidate Views in Dashboard]