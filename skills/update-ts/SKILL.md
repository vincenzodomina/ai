---
name: update-ts
description: Update TypeScript code to match the Python implementation.
---

## Task: Update Typescript to match Python

Implement the python equivalent in Typescript as close as possible with namings, signatures and order of code and code-block structures. 

### Rules:
- Apply the exact same names for all variables and functions inside the targeted Typescript file as in the python file. 
- Use the same if-else, loops and code structure and code order in general to match the python as closely as possible
- Match everything, even comments
- Make translation exceptions that are really necessary for Typescript to become functional, but document them for a later iteration.

### Goals:
- Keep the Typescript code as close as possible to the python code for easy comparison and maintenance.
- Optimize for human readability and maintainability when reading the python and Typescript version side by side.
- The resulting Typescript must be functionally equivalent to the python code end-to-end and must be able to run as is.
- Add Typescript type safety where possible and equivalent with the pydantic models without shortcutting by adding "as any" assertions.

### Non-Goals:
- Do not try to optimize, refactor, or improve the Typescript code beyond what is necessary to make it functional and equivalent to the python code.
- Do not add comments about the translation process or the differences into the code. You should highlight those things in chat instead.
- Do not add backwards compatibility, that has already been handled when updating the Python version, now the TS version has to catchup to match.

### Process:
1. Make a detailed plan first: Go through the mentioned file and identify all differences, look very closely to spot all of them. 
2. Ignore the already documented exceptions, which are needed to make it good typescript and to satisfy the differences to the Javascript versions of the corresponsing python libraries and language specifics used.
3. Propose all exact changes as diffs, including ordering, types, optionals, and missing fields and code blocks and have me confirm.
4. Then implement those changes needed to update the out of date Typescript version according to the golden truth of python.
5. Finally review the changes and curate the list of Typescript translation exceptions at the top of the file through adding comments of your added exceptions.

### Files to compare:
Mentioned after this set of instructions, optionally in addition to further hints and specifics for this task.