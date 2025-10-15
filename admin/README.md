# Admin (Angular) App

The Angular Admin client lets reviewers explore and approve items authored in the Flutter Creator app. It consumes the in-memory REST API exposed by the Flutter process, so be sure that app is running whenever you work with Admin.

## Functional Requirements
- Show a list of items with search input and category filter.
- Sort the list by quality score (highest first).
- Provide a detail view that exposes title, description, category, tags, quality score, and approval status.
- Allow approving items whose quality score is **≥ 90**. Approved items should remain clearly marked after the action.

## Implementation Notes
- Data lives entirely in memory; no external services or databases.
- The Angular app should fetch data and send approval updates via the local API served by Flutter.
- Reflect approval changes immediately in the UI to keep state consistent with the Creator app.

## Developer Tips
- Keep UI feedback tight: optimistically reflect approvals, then reconcile with the API response if needed.
- Consider shared models/interfaces so score and validation rules stay aligned with the Flutter side.
