---
name: code-guidelines
description: Use when implementing code. Read before code generation to know about how this project expects code to be structured and maintained and how to approach fixes, edits, code integration, external libraries, comments and docs.
---

### Code Guidelines

- ***Focused code edits:*** Only apply focused code edits, necessary for the task. Do not delete other unrelated comments. Do not apply fixes unrelated to the task, instead you can mention findings in your response.
- ***No quick fixes, workarounds or hacks:*** if not specifically asked for. Align with the PRDs in this project (read them, probably under docs/prds/) and their intended architecture and requirements. If you really need to solve the immediate problem, mention it in your response and explain why it is necessary and how it deviates from the PRDs and the ideal long term solution.
- ***Keep codebase size and complexity at a minimum:*** Every new line of code, helper, module, dependency or pattern should be justified in the response (not in code comments). Evaluate first if an exsting pattern, helper, module, dependency, or library can be reused or extended to solve the problem. Run the deletion test before adding code or re-inventing existing machinery. Apply the philosophy of deep modules with high locality, minimal coupling, lean/generalized interfaces.
- ***No unnecessary comments in the code:*** The code should be self-explanatory and should not need comments. Your response is where you can explain the code and the applied changes or historical prose about previous state, not in comments or doc strings. Comments should only be added when adding real value or explaining decisions and the "why", never for mentioning previous behavior or changes and never for repeating the code or pointing out the obvious. If added, comments should not span more than 1-2 lines.

### External Library Code

- ***Do not write external library code from memory:*** Treat remembered APIs, options, defaults, model names, integration patterns, and examples as potentially outdated. Libraries change frequently, so always verify library-related code against the version actually used in the project.
- ***Check the installed version first:*** Inspect the dependency version in the project manifest, lockfile, or the package's installed metadata, such as `node_modules/<package>/package.json`. When useful, compare it with the latest published version through the project's package manager, for example `npm view <package> version`.
- ***Use version-matched bundled docs and source when available:*** Prefer documentation, examples, type definitions, and source code shipped inside the installed package, such as `node_modules/<package>/docs/`, `node_modules/<package>/src/`, `node_modules/<package>/README.md`, and provider or framework companion package docs. These usually match the installed version better than memory or generic web snippets.
- ***Search current official docs when bundled docs are missing or incomplete:*** Use the library's official documentation site, API reference, migration guides, changelog, repository, and source code. When docs offer markdown versions, search endpoints, or version selectors, use them to locate exact current guidance.
- ***Verify related packages separately:*** Provider adapters, framework bindings, plugins, and companion packages can have their own docs, versions, defaults, and breaking changes. Check those packages directly before using their APIs.
- ***Do not guess unsupported behavior:*** If the docs and source do not confirm an API, option, default, or pattern, say so explicitly and choose a documented approach.
- ***Keep external-library changes minimal and explicit:*** Only install or upgrade packages that are required for the task, use the project's package manager, and avoid over-specifying options whose documented defaults already do the right thing.
- ***Validate after changing library integrations:*** Run the relevant type checker, linter, and tests. If errors appear, re-check the current docs and installed source before assuming the remembered API is correct.