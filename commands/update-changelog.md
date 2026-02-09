# Update CHANGELOG.md

## Workflow

1. Look into all recent commits since the last CHANGELOG.md entry date
2. Group and summarize the main topics based on the git commit messages and the code changes
3. Phrase update messages according to the existing message styling fix/add/remove/improve + a more human readable short concise and information dense message
3. Add a new CHANGELOG entry with a new date from today with
- a new semantic minor version update for additions
- a semantic patch version update if only fixes were applied
4. Run this workflow for @aidl/CHANGELOG.md, and also for @aidl-web/CHANGELOG.md if not specified otherwise
5. Sync the same updated semantic version in @aidl/pyproject.toml (under project.version, 3rd line) or in @aidl-web/package.json (under version, 3rd line)

## Rules:
- Only add a new update entry, if recent commits have not been added already
- Don't edit existing entries