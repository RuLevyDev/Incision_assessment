# Thrive Catalog Assignment

This monorepo contains the catalog take-home for the **Creator (Flutter)** and **Admin (Angular)** apps. Both apps share in-memory data exposed through the local HTTP API served by the Flutter app.

## Scope Overview
- Monorepo with two apps (`creator/` for Flutter, `admin/` for Angular).
- No external services or databases; everything must live in memory.
- The Angular app consumes the local API produced by Flutter.
- Suggested implementation timebox: **≤ 6 hours**.

## Quality Score Rules
The score starts at **40** and adjusts with:
- +20 if the title length exceeds 12 characters.
- +15 if the description length exceeds 60 characters.
- +10 when a category is set.
- +10 when at least one tag is added; +5 more when two or more tags are added.

### Approval Rules
- Only items with a score ≥ 90 can be approved in Admin.
- Approved items must be clearly marked on both clients.

## Applications
- **Creator (Flutter)**: create, validate, and manage items. Show the live quality score, forbid obvious special characters, and surface the approval state.
- **Admin (Angular)**: list, search, filter by category, sort by quality score, and approve items. Provide a detail view with all fields and the approval state.

Refer to `creator/README.md` and `admin/README.md` for app-specific guidance.
