---
name: update-deps
description: Update dependencies and Handle all (mentioned) version-bump-PRs from dependabot in the mentioned repos.
---

**Prep:**
First, Spin up the full local dev stack:
- Use the repo native setup env script and confirm its running end to end so its ready for the task below. 
- Exercise all the apps from the eventual monorepo (web app, cli, mobile as web version, agents and all those in different major configurations if applicable, e.g. if parallel implementations exist because of a migration phase). 
- Besides existing test suites (unit, integration, end-to-end) also use the Web UI (via browser, do real user testing and screenshots to verify functionality). 
- If images are not available via docker, use google image sources or other, this should not be a blocker. 
- Start docker daemon if you cant find docker. 
- Look for playwright or similar for browser testing, you should have a browser, do not prematurely assume you dont have one, check and install if needed.

**Task:**
Handle all (mentioned) version-bump-PRs from dependabot in the mentioned repos. 

**Workflow:**
1. First start with lowest hanging fruit/easy and safe ones to bump in a first sweep and PR that one separately, then exercise the potentially more breaking ones in smaller batches or individually, depending on change severity.  
2. Use the dependency-hygiene skill
3. Then also try to solve the high and critical advisory warnings from npm (should be done after dependabot PRs but double check in the end). 
4. Research what changes need to be applied to migrate our code to the new version (Prefer official migration guides and docs, CLI based scripts or helpers or cod mod supplied by the library provider, but only official ones!), otherwise look into both versions source code.
5. Then apply those changes and exercise with running full stack env and iterate on fixes and code migrations until working again and add those changes to the PR. For applied changes respect existing code guidelines, stay focused with comments and edits.
6. PR your changes in a dedicated PR and resolve/close the dependabot PRs.