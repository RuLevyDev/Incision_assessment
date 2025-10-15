# Creator (Flutter) App

The Flutter Creator app is responsible for authoring catalog items and exposing the in-memory HTTP API consumed by the Angular Admin client.

## Functional Requirements
- Create, edit, and delete items with fields: title, description, category, tags, quality score, and approval status.
- Validate inputs: forbid obvious special characters in textual fields and keep the form invalid until all mandatory data passes validation.
- Display the live quality score next to the title, updating as the user edits fields.
- Surface the approval state returned from the API so approved items are clearly marked.

## Quality Score Rules
Every item starts with a score of **40**, with adjustments:
- +20 when the title is longer than 12 characters.
- +15 when the description exceeds 60 characters.
- +10 when a category is set.
- +10 when at least one tag is added, plus +5 for two or more tags.

## Implementation Notes
- Maintain the in-memory store locally and expose endpoints that the Admin app can consume.
- Keep the Creator UI in sync with updates (e.g., approval status) coming from Admin via the API.
- Consider extracting shared models or constants so Flutter and Angular reuse the same score logic.
