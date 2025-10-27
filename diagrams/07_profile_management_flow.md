# 7. Profile Management Flow

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