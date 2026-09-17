---
name: setup-env
description: Set up the local development environment on a new machine, including all dependencies and configurations needed to run the full stack locally. Use only if explicitly asked to, because this can be time consuming and interfere with a local development environment.
---

Spin up the full local dev stack:
- Use the projects native setup env script and confirm its running end to end so its ready for the task stated afterwards (likely to be found at `./scripts/setup-local-env.sh` or similar). 
- If applicable, exercise all the apps from the monorepo (web app, cli, mobile as web version, agents and all those in different major configurations if applicable, e.g. if parallel implementations exist because of a migration phase). 
- Besides existing test suites (unit, integration, end-to-end) also use the Web UI (via a browser, to do real user testing and screenshots to verify visually). 
- If images are not available via docker registry or its blocked, try other sources as your Docker registry provider (Google Container Registry `gcr.io`). 
- Start docker daemon if you cant find docker. 
- Look for playwright or similar for browser testing, you should have a browser
- A fully running local dev stack is a requirement. Do not prematurely assume you are blocked, check and install missing dependencies if needed and try to work around blockers