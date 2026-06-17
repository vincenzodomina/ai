# Gate 2: Comments & Docstrings

Source of truth for the **Comments** gate of `improve-code`. Run the changed code through the [gate checklist](#the-gate-passfail) at the end. Everything before it is the reasoning and the worked examples behind those checks.

---

## Purpose

In a maintainable codebase, comments must **not** be used to make unclear code tolerable. They preserve information the code cannot express well: **intent, contracts, trade-offs, constraints, historical context, security/performance caveats, and non-obvious edge cases.**

This gate is about producing **higher-signal** comments and docstrings, not more of them. The best clean-code projects are not comment-free; they are **noise-free**: clear code, meaningful docstrings at boundaries, precise comments at danger points, tests for behavior, and ADRs/docs for the context code cannot carry.

---

## The Principle

> **Code says what happens. Names and types say what things are. Tests say what must stay true. Comments and docs say why, when, and what can go wrong.**

Good comments are **maintenance tools**, not decoration. Use them when they reduce future risk:

- risk of misuse
- risk of an unsafe refactor
- risk of re-litigating a settled decision
- risk of reintroducing a fixed bug
- risk of misunderstanding a business / security / performance constraint

---

## Where each kind of information belongs

Different information lives in different places. Putting it in the wrong layer is itself a finding.

| Information type | Best place |
| --- | --- |
| What the function/module/class is for | Docstring |
| How to call a public API correctly | Docstring |
| Argument meaning not obvious from name/type | Docstring |
| Return semantics, side effects, raised exceptions | Docstring |
| Why this algorithm/branch/workaround exists | Nearby block comment |
| Security or performance landmine | Nearby comment, plus possibly docs/ADR |
| Major architectural decision | ADR or design doc |
| Setup, development workflow, deployment | README / docs / runbook |
| Expected behavior and edge cases | Tests |
| Temporary known issue | Issue tracker + `TODO(issue-id): ...` |
| "This is weird because library X has bug Y" | Nearby comment with link to upstream issue |
| "Why Redis over Postgres here?" | ADR, not a code comment |

---

## How senior developers approach comments

The mature habit is not "more comments." It is **higher-signal comments**. The order of operations:

1. **First make the code clearer.** Better names, smaller functions, explicit types, simpler control flow, tests. A comment that compensates for a bad name is a FAIL — fix the name.
2. **Then document the public contract.** Public modules, classes, functions, methods, CLI entry points, package APIs, and framework extension points deserve docstrings.
3. **Then comment the surprising parts.** Caching behavior, consistency guarantees, security assumptions, race conditions, library quirks, performance trade-offs, deliberately "ugly" code.
4. **Move big context out of code.** Paragraphs of rationale, alternatives considered, historical reasoning, diagrams → an ADR/design doc. The code keeps a short pointer.
5. **Delete stale or redundant comments.** A comment that contradicts the code is worse than no comment (PEP 8). Keep them current or remove them.

---

## What makes a GOOD comment

A good comment answers one or more of these questions. It is **specific enough to be falsifiable** — "for performance" is weak; "avoids an N+1 in the invoice export path; see tests/perf/test_invoice_export.py" is useful.

### "Why is this here?"

```python
# Stripe may retry the same webhook for up to 3 days. We use the event ID
# as an idempotency key so duplicate deliveries do not create duplicate orders.
if order_events.exists(event.id):
    return
```

### "What invariant must not be broken?"

```python
# Keep this check before decrypting the payload. Failed auth must not reveal
# whether the referenced object exists.
if not can_read(user, object_id):
    raise NotFoundError
```

### "Why this implementation instead of the obvious one?"

```python
# Do not replace this with `datetime.fromisoformat`.
# Vendor timestamps sometimes include leap-second values that fromisoformat rejects.
timestamp = parse_vendor_timestamp(raw["created_at"])
```

This prevents a future "cleanup" that reintroduces a bug.

### "What external dependency behaves unexpectedly?"

```python
# boto3 retries throttled requests, but not validation errors. We retry this
# block because the service sometimes returns ValidationException while the
# index is still propagating.
wait_for_index_to_be_queryable(index_name)
```

### "What is the contract?"

```python
def reserve_inventory(order_id: OrderId) -> Reservation:
    """Reserve stock for an order.

    The operation is idempotent for a given order ID. If a reservation already
    exists, it is returned unchanged.

    Raises:
        OutOfStockError: If any item cannot be reserved.
        OrderNotFoundError: If the order does not exist.
    """
```

This documents behavior callers depend on, not just what the code does.

---

## What makes a BAD comment

Bad comments repeat what the code already says, compensate for weak names, or carry noise.

| Smell | Fix |
| --- | --- |
| `retry_count += 1  # Increment retry count.` | Delete the comment. |
| `# TODO: fix this` | `# TODO(SEC-1842): Replace temporary allowlist after partner rotates keys. Remove after 2026-08-01.` |
| `# This function processes data` over `def process_data(data):` | Rename: `def normalize_invoice_rows(rows: Iterable[RawInvoiceRow]) -> list[InvoiceRow]:` and drop the comment. |
| `# Magic. Do not touch.` | Explain the real constraint (see below). |
| Commented-out code | Delete it. Git remembers. |
| Author names, creation dates, "modified by" changelogs | Delete. Version control tracks this better. |
| Emotional notes ("stupid library", "hacky fix") | Delete or replace with the concrete reason. |

"Magic. Do not touch." → a comment that actually earns its place:

```python
# The API rejects batches over 500 records, but latency rises sharply above 200.
# Keep this at 200 unless the vendor limit or p95 latency target changes.
BATCH_SIZE = 200
```

A comment is **suspicious** whenever it leans on "clearly", "obviously", "hack", "temporary", "for performance", or "do not touch" without naming the concrete reason.

---

## Docstrings

Baseline: **PEP 257** plus one chosen project style (Google, NumPy, or reST/Sphinx) applied **consistently**. Use triple double quotes, even for one-liners. **Do not restate the signature** — it is introspectable. **Do not duplicate obvious type hints** in `Args:`.

### One-line docstrings

```python
def utc_now() -> datetime:
    """Return the current UTC time."""          # good: short, command-style, ends in a period
```

```python
def utc_now() -> datetime:
    """utc_now() -> datetime"""                  # bad: restates the signature, adds nothing
```

### Multi-line docstrings — summary line, blank line, body

A docstring earns its keep when it explains a rule or a dangerous option, not when it narrates the code.

```python
def calculate_invoice_total(
    invoice: Invoice,
    *,
    include_pending_adjustments: bool = False,
) -> Money:
    """Calculate the payable total for an invoice.

    Pending adjustments are excluded by default because they may still be
    rejected by the billing provider. Set `include_pending_adjustments` only for
    preview screens, not for settlement.

    Raises:
        CurrencyMismatchError: If line items use different currencies.
    """
```

### Function / method docstrings

For public or non-obvious functions, include what a caller needs to use it correctly: side effects, units, exceptions, security expectations. A docstring should let someone call the function **without reading its body**, and should avoid implementation details unless those details affect usage.

```python
def create_session(
    user_id: UserId,
    *,
    remember_me: bool,
    ip_address: str,
) -> SessionToken:
    """Create a signed login session for a user.

    Sessions created with `remember_me=True` expire after 30 days. Other
    sessions expire after 12 hours. The caller is responsible for verifying
    that the user has already completed MFA.

    Args:
        user_id: User receiving the session.
        remember_me: Whether to issue a long-lived session.
        ip_address: Source IP used for audit logging and anomaly detection.

    Returns:
        A signed session token that can be sent to the client.

    Raises:
        UserDisabledError: If the user is disabled.
    """
```

Do **not** add noise like `subject: A string.` Document an argument only when its meaning, unit, allowed values, side effects, or constraints are not obvious.

### Module docstrings

Prefer a **module docstring** over a giant banner comment, especially when the file is a subsystem boundary (auth, billing, policy, event processing, caching, permissions, serialization, migrations, vendor integration). PEP 257: list exported objects with short summaries; for scripts, make it usable as a `--help`/usage message (CLI syntax, env vars, files).

```python
"""Invoice settlement orchestration.

This module converts approved invoices into settlement requests for the payment
provider. It intentionally does not validate invoice business rules; validation
must happen before an invoice reaches `ApprovedInvoice`.

Important constraints:
- Settlement requests must be idempotent by invoice ID.
- Provider API calls must go through `PaymentGatewayClient` to preserve audit
  logging and retry behavior.
- Do not import ORM models here; this module is used by the async worker and
  the CLI reconciliation tool.
"""
```

### Top of file

```python
#!/usr/bin/env python3
# Copyright ...
# License ...
"""Short module summary.

Longer module explanation if useful.
"""
from __future__ import annotations

import ...
```

Use top-of-file comments only for: license/copyright, generated-file warnings, an unusual shebang, rarely an encoding line, and the module docstring. **Avoid** giant headers with author names, creation dates, or changelogs — Git tracks that better.

### Private / internal methods

No ceremonial docstrings. PEP 8: docstrings are not required for non-public methods; add a comment after `def` when behavior needs explaining. A useful comment beats an empty docstring:

```python
def _bucket_key(self, user_id: UserId, route: str) -> str:
    # Include the route so a noisy endpoint does not consume the user's entire
    # quota for unrelated API calls.
    return f"{user_id}:{route}"
```

Complex internal code may still warrant a docstring — the test is usefulness and consistency, not ceremony.

---

## Where non-code context should live

This is the most important judgment the gate enforces: **not all context belongs in a comment.** Use a layered model.

**In a code comment** — when the context is needed to safely modify the next few lines, is tightly coupled to a local detail, fits in a paragraph or two, and will be read exactly where the change happens:

```python
# This must remain a constant-time comparison. Replacing it with `==` can leak
# token validity through timing differences.
if not hmac.compare_digest(expected, actual):
    raise InvalidTokenError
```

**In a docstring** — when the context affects callers: side effects, idempotency, transaction boundaries, retry behavior, exceptions, security expectations, units, concurrency guarantees, mutability, whether input is consumed, whether results are cached:

```python
def get_user_permissions(user_id: UserId) -> PermissionSet:
    """Return effective permissions for a user.

    Results are cached for up to 60 seconds. Do not use this function for
    authorization checks immediately after permission changes; use
    `get_user_permissions_uncached` instead.
    """
```

**In tests** — when the rule is executable behavior ("duplicate webhook events do not create duplicate orders", "disabled users cannot receive new sessions"):

```python
def test_permission_cache_does_not_affect_uncached_authorization_check():
    ...
```

**In an ADR** — when the context answers *why this architecture, what alternatives were rejected, what trade-offs were accepted, what would make us revisit.* The code keeps a short pointer; the ADR carries the reasoning:

```python
# See docs/adr/0017-use-event-sourcing-for-ledger.md before changing this flow.
# The append-only model is required for audit reconstruction.
ledger.append(event)
```

**In README / docs** — how to run the project, how the pieces fit, local setup, deployment, operational assumptions, onboarding, troubleshooting, diagrams, API usage examples. A useful layout:

```text
README.md
docs/
  architecture/   overview.md, data-flow.md
  adr/            0001-use-postgres.md, 0002-use-outbox-pattern.md
  runbooks/       failed-payments.md, webhook-replay.md
  security/       auth-model.md, threat-model.md
  development/    local-setup.md, testing.md
```

(The Diátaxis split — tutorials / how-to / reference / explanation — is a good way to organize the `docs/` tree.)

---

## The Gate (PASS / FAIL)

Walk the changed code through this checklist. The gate is **FAIL** while any item below is true; fix or escalate each, then re-check.

### Comments

- [ ] No comment **restates the code** or explains standard language syntax.
- [ ] No comment **compensates for a bad name** — the name was fixed instead.
- [ ] No **commented-out code**, author/date/changelog headers, or emotional notes.
- [ ] No **vague TODOs** — every TODO has an issue id and (where relevant) a removal condition: `TODO(ISSUE-123): ... remove after <date/condition>`.
- [ ] Every **non-obvious "why"** at a danger point is captured: security ordering, library/vendor quirk, performance trade-off, deliberate "ugly" code, an invariant that must not break.
- [ ] Each comment is **specific/falsifiable** (names the actual constraint, metric, bug, or trade-off) — no bare "for performance" / "do not touch".
- [ ] No paragraphs of **architectural rationale wedged into a comment** — that lives in an ADR/doc with a short pointer from the code.

### Docstrings

- [ ] Every **public** module / class / function / method / CLI entry point / framework hook has a docstring.
- [ ] Docstrings document the **contract** callers depend on (side effects, exceptions, idempotency, units, security/concurrency/caching expectations), not a restatement of the body.
- [ ] Docstrings **do not restate the signature** or duplicate obvious type hints; non-obvious args/units/allowed-values are documented.
- [ ] One chosen docstring **style is used consistently**; triple double quotes; one-liners are short and command-style.
- [ ] **Subsystem-boundary modules** have a module docstring stating intent and key constraints.
- [ ] No **ceremonial empty docstrings** on trivial private helpers (use a short comment if anything).

### Context placement

- [ ] Caller-visible context is in the **docstring**, not buried in a body comment.
- [ ] Executable rules are covered by **tests**, not only described in prose.
- [ ] Cross-cutting decisions point to an **ADR/doc**; setup/ops live in **README/docs**.

A gate run that finds none of the above is a clean **PASS** — record it and move on without inventing churn.

---

## Review questions

For each comment or docstring, ask:

| Criterion | Question |
| --- | --- |
| Necessary | Would a competent maintainer miss this from code/tests/types alone? |
| Local | Is it close to the code it explains? |
| Stable | Is it unlikely to become false after a small refactor? |
| Specific | Does it name the actual constraint, bug, issue, metric, or trade-off? |
| Actionable | Does it help someone safely change or use the code? |
| Verifiable | Can someone check whether it is still true? |
| Non-duplicative | Does it avoid repeating the obvious? |
| Maintained | Will it be reviewed when nearby code changes? |
| Audience-aware | Is it written for future maintainers, not the original author? |

And the placement question:

> Should this be a comment, a docstring, a test, an ADR, or external documentation?

---

## Worked example: clean, maintainable, informative

```python
"""Webhook ingestion for payment provider events.

The ingestion path is intentionally idempotent. Payment providers may deliver
the same event multiple times, out of order, or after a delay. This module
stores provider event IDs before dispatching domain handlers so retries cannot
create duplicate ledger entries.

See:
    docs/adr/0012-use-idempotent-webhook-ingestion.md
"""
from __future__ import annotations


def ingest_payment_event(raw_event: Mapping[str, object]) -> None:
    """Validate, store, and dispatch a payment provider event.

    The function is safe to call repeatedly with the same provider event ID.
    Duplicate events are acknowledged but not dispatched again.

    Raises:
        InvalidSignatureError: If the event signature cannot be verified.
        UnsupportedEventError: If the event type is unknown.
    """
    event = parse_and_verify(raw_event)

    # Store the event before dispatching. If the worker crashes after this
    # point, replay will skip dispatch rather than risk double-posting ledger
    # entries. See ADR-0012 for the accepted trade-off.
    if not event_store.insert_once(event.provider_event_id, event):
        return

    dispatch(event)
```

Why this passes: the **module docstring** gives subsystem intent and a pointer to the full trade-off; the **function docstring** states caller-visible behavior and exceptions; the **local comment** explains a subtle ordering decision; the **ADR** holds the deep reasoning; the code stays readable.

---

## Note for non-Python code (TS/JS and others)

The principles are language-agnostic; only the mechanism changes. In TypeScript/JavaScript, the "docstring" layer is **TSDoc/JSDoc** (`/** ... */`) on exported functions, classes, and modules — same rules: document the contract (params with non-obvious meaning, return semantics, thrown errors, side effects), don't restate types the signature already provides, and keep the "why" in nearby `//` comments at danger points. The context-placement layers (comment / docstring / test / ADR / docs) apply unchanged.

---

## References

- PEP 257 — Docstring Conventions
- PEP 8 — Style Guide for Python Code (comments section)
- Google Python Style Guide — docstrings
- ADRs — Google Cloud / AWS / Microsoft well-architected guidance
- Diátaxis — documentation framework (tutorials / how-to / reference / explanation)
