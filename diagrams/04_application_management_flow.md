# 4. Application Management Flow (Employer)

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