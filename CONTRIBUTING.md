# Contributing to Calmer Commute

This guide explains how the team should work with this repository.

## Branches

- `main`: Stable and release-ready code
- `development`: Default integration branch
- `AI`: Forecasting and AI work
- `data`: Dataset validation, cleaning, schemas and pipelines
- `frontend`: Website interface
- `backend`: APIs, services and database integration

## Standard Workflow

1. Work in the branch relevant to your area.
2. Synchronise that branch with `development`.
3. Make a small, focused change.
4. Test the change locally.
5. Commit using a clear message.
6. Push to the specialist branch.
7. Open a pull request into `development`.
8. Request review from another team member.
9. Address review comments and resolve conflicts.
10. Merge only after required checks are complete.

## Pull Request Direction

Normal integration:

`AI`, `data`, `frontend` or `backend` → `development`

Release integration:

`development` → `main`

Do not directly push completed implementation work into `main` or `development`.

## Commit Message Examples

- `feat: add route comparison endpoint`
- `fix: handle missing sensor timestamps`
- `data: normalise pedestrian observations`
- `docs: document City of Melbourne attribution`
- `test: add route scoring tests`
- `chore: initialise project structure`

## Opening a Pull Request

1. Push your specialist branch to GitHub.
2. Open the repository on GitHub.
3. Select **Pull requests**.
4. Select **New pull request**.
5. Set the base branch to `development`.
6. Set the compare branch to your specialist branch.
7. Add a clear title and description.
8. Link the relevant Epic, User Story and LeanKit card.
9. State what testing was completed.
10. Add screenshots or evidence where relevant.
11. Request a reviewer.

## Pull Request Description

Each pull request should include:

### Summary
What changed?

### Purpose
Why was the change needed?

### Related Work
- Epic:
- User Story:
- LeanKit card:

### Testing
What was tested?

### Evidence
Screenshots, sample outputs, reports or links.

### Known Limitations
Any unresolved issues or future work.

## Data Rules

- Keep original data separate from processed data.
- Record the authoritative source for each dataset.
- Document licence and attribution requirements.
- Document freshness and missing-data rules.
- Preserve timestamps and source identifiers for traceability.
- Do not commit unnecessary large raw datasets.
- Never commit credentials, API keys or sensitive information.

## Review Expectations

Reviewers should check:

- Alignment with the relevant Epic and User Story
- Satisfaction of Acceptance Criteria
- Code and documentation quality
- Test evidence
- Data quality and provenance
- Responsible wording and limitations
- Potential integration conflicts
- Whether unnecessary scope has been introduced

## Definition of Done

A contribution is complete when:

- Relevant Acceptance Criteria are satisfied
- Tests pass
- Code or artefacts are reviewed
- Documentation is updated
- No critical or high-priority defects remain
- Evidence is linked
- The pull request has been approved and merged