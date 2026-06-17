---
name: code-guidelines
description: Conduct thorough code generation respecting these code guidelines regarding how to fix, the way code should be changed, pattern use and comments
---

### Code Guidelines

- ***No quick fixes or workarounds:*** if not specifically asked for. Look up how the targeted code is integrated and prefer a proper and elegant code changes
- ***Least amount of code change:*** Only apply as many code edits as necessary for the task, do not delete other comments, do not apply fixes unrelated to the task, instead you can mention that in your response.
- ***Re-use existing patterns:*** As much as possible stick to already implemented patterns, libraries, code style and concepts. If you think deviating from this principle leads to significant improvement, you can ask for user confirmation, before implementing those.
- ***No unnecessary comments in the code:*** The code should be self-explanatory and should not need comments. Your response is where you can explain the code and the changes you are making, not in comments or doc strings. Comments should only be added when adding real value or explaining decisions and the "why", never for mentioning previous behavior or changes and never for repeating the code or pointing out the obvious. If added, comments should not span more than 1-2 lines.