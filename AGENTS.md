# Instructions for Agents


### Code Guidelines

- ***No quick fixes or workarounds:*** if not specifically asked for. Look up how the targeted code is integrated and prefer a proper and elegant code changes
- ***Least amount of code change:*** Only apply as many code edits as necessary for the task, do not delete other comments, do not apply fixes unrelated to the task, instead you can mention that in your response.
- ***Re-use existing patterns:*** As much as possible stick to already implemented patterns, libraries, code style and concepts. If you think deviating from this principle leads to significant improvement, you can ask for user confirmation, before implementing those.
- ***Verify generated code:***: Always run the existing tests to verify new generated code with `uv run pytest tests --no-cov`