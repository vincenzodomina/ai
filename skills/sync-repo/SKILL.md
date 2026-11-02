---
name: sync-repo
description: Sync selected repository contents in bulk or mirror upstream PRs into a downstream repository while preserving its scope and divergence.
---

# Sync Repo

The **source of truth-repo** owns shared code and functionality. The **synced-repo** receives selected updates and owns its local differences. This relationship is one-way: keep sync policy, tracking, and adaptations in the synced-repo; the source of truth-repo needs no downstream awareness or changes.

## 1. Establish the contract

Read the synced-repo's root-level Markdown files; If documented already or explicitely requested, document:

- Source repository and branch; source-to-target path mappings.
- Explicit included paths, overriding exclusions, and intentionally removed paths that must stay absent.
- Protected downstream files or regions, including configuration, dependency, and release conventions.
- Last covered source commit/PR set, intentional skips, and pending downstream PRs separately from completed imports.

Scope follows this contract, not folder presence or a monorepo-wide glob. Resolve material uncertainty before editing affected paths; continue with unambiguous work. **Done:** every candidate path has a mapping and disposition.

## 2. Compare both histories

Fetch current history and locate the previous import using the contract and commit/PR evidence, not dates alone. Account for pending imports before repeating work. Compare source changes since that baseline with subsequent downstream changes, including local work, deletions, and renames.

Preserve downstream divergence by applying the source delta, rather than replacing a divergent file wholesale. New source files inside the agreed scope are eligible; a previously removed target path remains excluded unless the user changes the contract. **Done:** distinguish new source work, already covered changes, exclusions, and overlaps requiring resolution.

## 3. Apply the requested mode

- **Bulk sync:** mechanically copy the selected snapshot or cumulative delta in one commit/PR. Propagate source deletions only within scope and after checking downstream divergence.
- **PR mirroring:** process selected source PRs in dependency order; default to newly merged PRs. Keep one downstream PR per nonempty scoped change. Reduce mixed-scope PRs and skip empty ones. Include required follow-up commits; account separately for release commits. Build on pending downstream branches when necessary.

Keep imported content byte-identical at the selected source revision, including mapped paths and file modes. Preserve protected target differences as explicit exceptions. If overlapping edits cannot satisfy both, stop that portion and resolve ownership instead of silently choosing either side.

Shared root manifests, lockfiles, and release notes follow the target contract. Generate lockfiles from retained target workspaces; dependency failures are not permission to restore excluded code or broaden scope. Keep adaptations minimal and recorded. Describe actual functionality in PRs;

**Done:** every selected change is applied, intentionally skipped, or explicitly unresolved.

## 4. Verify and record

Check each PR diff and the cumulative result: excluded paths are unchanged, protected removals remain absent, imported bytes match source, and every deviation is an accounted-for downstream exception. Verify preserved divergence against the pre-update target and run checks appropriate to the retained changes.

Update the synced-repo's contract with verified coverage and actual pending/merged state; unresolved work must remain visible. Report included/skipped work, exceptions, and validation limits. Publish or merge only within the user's authorization; an update request alone does not authorize merging. After authorized merges, verify the resulting target tree against the validated result.
