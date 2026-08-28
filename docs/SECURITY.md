# Security

**Status:** Phase 0 audit. Findings are against the current build.

---

## Findings

### SEC-1 — API keys are compiled into the shipped client — **Critical**

`--dart-define` injects at *build* time. The values are embedded in the
compiled artifact: readable in the web bundle's JavaScript, extractable
from an APK or IPA with standard tooling.

```dart
// lib/services/groq_service.dart:56
static const String _apiKey = String.fromEnvironment('GROQ_API_KEY');
// lib/services/dish_image_service.dart:42
static const String _pexelsKey = String.fromEnvironment('PEXELS_API_KEY');
```

**Impact:** anyone with the app can extract both keys and spend the
owner's quota. Groq bills per token; Pexels caps at 20,000 requests per
month. There is no per-user limit, so a single extracted key can exhaust
the account.

**Fix:** all provider calls move behind the backend. The client ships
with a backend base URL and holds only the signed-in user's own JWT.
This is the single highest-priority item in Phase 1 and the reason the
app cannot ship to a store in its current form.

**Operational note:** the keys used during development have been pasted
into chat transcripts and must be treated as compromised. Rotate both
before any deployment.

---

### SEC-2 — Prompt injection through the chat surface — **High**

User text is concatenated into the same message array that carries the
dietary-safety system prompt:

```dart
// lib/services/groq_service.dart:234
{'role': 'user', 'content': message}
```

A user can instruct the assistant to disregard prior instructions. For a
general chatbot that is embarrassing. **For an app that makes allergy
claims it is a safety issue** — the model can be talked out of the one
rule that matters most.

**Fix, layered:**
1. Never rely on the model for allergy enforcement. Filter candidates
   server-side, before generation. (Also ARCHITECTURE.md §2.)
2. Validate and length-cap input server-side.
3. Re-assert safety constraints in a trailing system message, after user
   content, so the last instruction the model reads is ours.
4. Validate output shape; reject anything violating a stored allergy.

Defence 1 is the real one. The rest reduce noise.

---

### SEC-3 — No rate limiting anywhere — **High**

No per-user or per-device limit on LLM calls. One client in a loop can
exhaust the Groq quota and the Pexels ceiling. Fixed by SEC-1's backend
plus a per-user token budget.

---

### SEC-4 — Failures are silent — **Medium**

13 `catch (_)` blocks discard errors with no logging. Good for
resilience, bad for operations: in production nobody would know the photo
cascade had been failing for a week. Fix with structured logging behind
the same catch, plus crash reporting.

---

### SEC-5 — No privacy surface — **Medium**

The app stores dietary preferences, allergies, and behavioural history.
Today that is device-local, which limits exposure, but there is no
privacy policy, no delete-my-data path, and no export. Required before
either app store will accept a submission, and required in substance the
moment any of it moves server-side.

---

### SEC-6 — Unvalidated third-party image URLs — **Low**

`Image.network` renders whatever URL the API returns. Both current
sources are reputable and the blast radius is small, but the URL host
should be allowlisted once a backend exists to do it centrally.

---

## Handling rules

**Allergies are safety-sensitive.** Stored separately from taste
preferences, applied as an absolute pre-filter, never a scoring weight,
never enforced by the model alone. The UI must always tell users to
confirm allergens and cross-contamination with the restaurant, and must
never state that a meal is safe.

**Location** is requested only when a feature needs it, with an
explanation shown before the OS prompt, and coarse precision unless fine
precision is genuinely required.

**Secrets** live in the backend environment only. `.env.example` is
committed; `.env` never is. No secret in any Flutter source file, ever.

---

## Pre-launch checklist

- [ ] All provider calls proxied through the backend (SEC-1)
- [ ] Development keys rotated — current ones are compromised
- [ ] Server-side allergy filtering, with tests (SEC-2)
- [ ] Per-user rate limits (SEC-3)
- [ ] Structured logging + crash reporting (SEC-4)
- [ ] Privacy policy, terms, delete-account flow (SEC-5)
- [ ] Location permission strings and rationale screens
- [ ] Dependency audit
- [ ] Secrets scanning in CI
