# Privacy and Retention Rule

## Scope

This rule applies to user preferences and journey information collected or displayed by the Calmer Commute onboarding vertical slice.

## Retention rule

**Journey preferences and journey information are kept only in browser memory for the active session. They are not persisted to local storage, cookies, databases, or any backend store, and they are not uploaded as personal profile data.**

In practical terms:

- Origin, destination, crowd-limit threshold, selected route, and on-screen journey state exist only as React component state while the page is open.
- Closing or refreshing the browser tab clears that state.
- The application does not create a user account, preference profile, or journey history record.
- Provider credentials (for example Google Maps API keys) remain server-side in environment configuration and are never written into the client repository as secrets.

## Allowed processing during a session

Transient processing required to deliver the journey experience is allowed, including:

- Sending origin and destination addresses to Google routing / places services to obtain public-transport alternatives.
- Requesting crowd, forecast, and refuge responses for the current journey context.
- Rendering sensor and route classifications on screen for the current session only.

These requests are functional journey lookups, not long-term retention of user preferences.

## If permanent storage is introduced later

Any future change that stores preferences or journey history must:

1. Update this document with purpose, retention period, storage location, and deletion method.
2. Obtain team approval before release.
3. Add matching privacy and security checklist evidence in `docs/testing/VERTICAL_SLICE_SECURITY_ASSESSMENT.md`.

Until that happens, the default rule above remains in force: **session-only, non-persistent, non-uploaded preference and journey state.**
