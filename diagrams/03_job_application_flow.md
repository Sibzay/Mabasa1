# 3. Job Application Flow (Employee)

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