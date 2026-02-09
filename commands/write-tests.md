# Task: Write Tests

1. Scan the codebase to understand the spec or implementation of the pointed feature provided by the user and return clarification questions if needed for unclear or ambiguous parts.

2. Architect a test-suite blueprint (user stories + test cases) that covers API contracts, error handling, durability/retries, and integration boundaries—written as plain text so it can guide later implementation and automation. Present this to the user for confirmation.

3. Write the tests according to the best practices elaborated below.

## Principles (from [Avoid Nesting when you’re Testing](https://kentcdodds.com/blog/avoid-nesting-when-youre-testing) and [Better Test Setup with Disposable Objects](https://www.epicweb.dev/better-test-setup-with-disposable-objects))

- **Prefer flat tests**: Keep each test case self-contained so you can understand it without scanning `before*` hooks, nested groups, or shared state.
- **Make prerequisites explicit**: A reader should see *exactly* what this test needs (data, stubs, environment, server, user state) inside the test body or in a helper used by the test.
- **Avoid hasty abstractions (AHA)**: Duplicate a few lines until change pressure is real; then abstract carefully.
- **Don’t get clever in tests**: Optimize for clarity and debuggability over “DRY” or “architected” setup.

## Concrete rules to follow

### Test structure
- **Write tests as “setup → action → assertion”** in one place.
- **Avoid nested test grouping for behavior**; group by file/module and test names instead.
- **Avoid mutable outer-scope variables** populated by hooks/fixtures; prefer locals returned from helpers.

### Reuse without hidden coupling
- **Inline setup if it’s small** (clarity beats micro-DRY).
- **When reuse is justified, use helper functions/factories** that *return everything the test uses* (no mutation of shared variables).

```python
def make_user(username="michelle", password="smith"):
    return {"username": username, "password": password}

def setup_login_form():
    handle_submit = Spy()
    page = render_login(on_submit=handle_submit)
    return page, handle_submit

def test_submits_username_and_password():
    page, handle_submit = setup_login_form()
    user = make_user()

    page.type("username", user["username"])
    page.type("password", user["password"])
    page.click("submit")

    handle_submit.assert_called_once_with(user)
```

### Cleanup you can’t forget
- **Co-locate setup with cleanup** using a “disposable resource” pattern.
- **Guarantee cleanup even if assertions fail** (don’t rely on “last line closes server”).

Python equivalents:
- **Context managers** (`with ...:` / `async with ...:`) for resources.
- **`try/finally`** when a context manager isn’t available.
- **Pytest `yield` fixtures** when you truly need framework-managed lifecycle (use sparingly; keep dependencies shallow and explicit).

```python
from contextlib import contextmanager

@contextmanager
def test_server():
    server = start_server()
    try:
        yield server
    finally:
        server.close()

def test_user_endpoint():
    with test_server() as server:
        server.route("/user", user_handler)

        res = server.get("/user")
        assert res.status_code == 200
```

## Quick checklist for every test
- **Can I understand this test without reading any other scope?**
- **Are prerequisites explicit (not hidden in hooks/fixtures)?**
- **If I reused setup, is it via a helper that returns locals (not shared mutation)?**
- **Is cleanup guaranteed on failure (context manager / `finally` / yield-fixture teardown)?**
- **Is the test name a clear behavioral statement?**