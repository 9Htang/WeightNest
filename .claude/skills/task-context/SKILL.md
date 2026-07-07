---
name: task-context
description: This skill should be used when the user asks to "collect task context", "gather relevant code", "dump task snippets", "context for task", "save code context", "collect code for", or provides a task description and wants all related code gathered into a directory of complete files plus a README index.
---

# Task Context Collector

Gather every file relevant to a task into `temp/{task-slug}/` by **path-only**
search, then **copy** the files with shell commands. The model never reads a
file's contents — only paths. Output is a directory of real files you can
open in your editor, plus a README index.

## Principle

**Identify what to copy without reading it.** Use `Grep` with
`output_mode: files_with_matches` and `Glob` — they return file *paths*
without content. Then `Copy-Item` via PowerShell copies files at the OS
level without the model seeing their contents.

## Workflow

### Step 1 — Parse the task

Extract the task description from the user's request. The task may be phrased
as:

- "Collect context for: fix the breeding weight sync bug"
- "Gather code for the medication reminder feature"
- "Dump task snippets: refactor gallery thumbnail caching"
- Any direct statement of what needs to be done

If the task description is ambiguous, ask for a single-sentence summary before
proceeding.

### Step 2 — Derive the slug

Convert the task description to a directory name:

1. Lowercase
2. Replace non-alphanumeric characters with hyphens
3. Collapse consecutive hyphens into one
4. Strip leading/trailing hyphens

Example: "Fix the breeding weight sync bug" slug is
`fix-the-breeding-weight-sync-bug`.

The output directory will be `temp/{slug}/` relative to the project root.

### Step 3 — Parallel search phase

Fire all searches below **in a single parallel batch**. Every `Grep` call
(except Search C) uses `output_mode: files_with_matches` — the model sees
only file paths, never file contents. All calls are independent.

---

**Search A — Keyword grep.** Extract 2–5 key terms from the task description:
entity names, feature names, field names, screen/widget names, route names.
Grep for each term under `lib/`. Use `-i` for case-insensitive search.

```
Grep: pattern="{term_1}" path="lib/" output_mode="files_with_matches" -i
Grep: pattern="{term_2}" path="lib/" output_mode="files_with_matches" -i
Grep: pattern="{term_3}" path="lib/" output_mode="files_with_matches" -i
```

---

**Search B — Naming convention glob.** Infer the feature name from the task
(e.g. "breeding weight sync" → feature is `breeding`). Glob for naming
convention patterns:

```
Glob: **/{feature}/**/*.dart
Glob: **/{feature}*.dart
Glob: **/*{feature}*.dart
```

Standard naming patterns in this project:
- `{feature}/{feature}_screen.dart`
- `{feature}/{feature}_repository.dart`
- `{feature}/{feature}_plugin.dart`
- `{feature}/{feature}_tables.dart`
- `{feature}/{feature}_provider.dart`
- `{feature}/{feature}_section.dart`
- `{feature}/screens/*.dart`
- `{feature}/widgets/*.dart`

When the task crosses multiple features (e.g. "make nutrition read stage
data"), run naming-convention globs for each feature.

---

**Search C — Registration / wiring points (CONTENT-MODE EXCEPTION).**

> ⚠️ **This is the ONLY search that reads file content.** It targets exactly
> these 2–4 small wiring files and nothing else. Every other search uses
> `output_mode: files_with_matches`. This exception exists because these
> files are tiny (< 50 lines each) and always relevant — reading them
> reveals how the feature is wired into the app.

Always check these regardless of task:

```
Grep: pattern="{feature_name}" path="lib/plugins/plugins.dart" output_mode="content" -i
Grep: pattern="{feature_name}" path="lib/providers.dart" output_mode="content" -i (if exists)
Glob: lib/app.dart
Glob: lib/core/plugin*.dart
```

If the task mentions events or cross-plugin communication, also:

```
Glob: lib/core/event_bus*.dart
```

---

**Search D — Shared infrastructure.** If the task touches a concern that
crosses features (stages, sync, alerts, tasks, themes, grid, calendar),
search the shared layers. First broad glob, then keyword grep within:

```
Glob: lib/services/**/*.dart
Glob: lib/repositories/**/*.dart
Glob: lib/core/**/*.dart
Glob: lib/database/**/*.dart
```

Then grep for the feature keyword within those directories:

```
Grep: pattern="{feature_name}" path="lib/services/" output_mode="files_with_matches" -i
Grep: pattern="{feature_name}" path="lib/repositories/" output_mode="files_with_matches" -i
Grep: pattern="{feature_name}" path="lib/core/" output_mode="files_with_matches" -i
```

For UI/token tasks, also:

```
Glob: lib/theme/**/*.dart
```

---

### Step 4 — Deduplicate and prioritize

Merge all path results into a single set, deduplicated.

**Priority scoring** (higher = more relevant):

| Match source | Points |
|---|---|
| Matched in Search B (naming convention — exact feature match) | +3 |
| Hit in `lib/plugins/plugins.dart` or `lib/providers.dart` (Search C) | +2 |
| Each keyword hit from Search A | +1 |
| Matched in Search D (shared infrastructure) | +1 |
| File is a `.dart` file under `lib/` | +1 |

Sort descending by score. Take the top 30.

**Always include** (count toward the 30 cap):
- `lib/plugins/plugins.dart` — the registration file
- The feature's plugin file (e.g. `lib/plugins/breeding/breeding_plugin.dart`)
- The feature's table file (e.g. `lib/plugins/breeding/breeding_tables.dart`)

If more than 30 are tied for the lowest score, keep the ones matched by the
most distinct search categories.

If more than 30 are relevant, note the count of omitted files — they will be
listed in the README.

### Step 5 — Create the output directory

```powershell
New-Item -ItemType Directory -Force "temp/{slug}"
```

`-Force` overwrites any existing directory at that path without prompting.
This is safe because `temp/` is gitignored and intentionally disposable.

### Step 6 — Copy files (model never reads them)

**First, detect basename collisions.** Scan the prioritized file list. Group
all files by basename (the filename after the last `/`). If any basename
appears more than once, prefix **all** files sharing that basename with
their immediate parent directory name:

```
Before:  lib/feature_a/screen.dart, lib/feature_b/screen.dart
After:   feature_a_screen.dart, feature_b_screen.dart

Before:  lib/breeding/screen.dart  (appears once — no collision)
After:   screen.dart               (keeps plain basename)
```

Unambiguous basenames (appearing exactly once) stay as-is.

**Then copy in one batch.** Issue all `Copy-Item` commands together:

```powershell
Copy-Item "lib/plugins/breeding/breeding_plugin.dart" "temp/{slug}/breeding_plugin.dart"
Copy-Item "lib/plugins/breeding/breeding_tables.dart" "temp/{slug}/breeding_tables.dart"
Copy-Item "lib/plugins/breeding/breeding_repository.dart" "temp/{slug}/breeding_repository.dart"
# ... one Copy-Item per file, up to 30
```

The model never reads file contents. `Copy-Item` copies bytes at the OS level
— zero token burn on file content.

### Step 7 — Write the README index

Create `temp/{slug}/README.md` with this structure:

```markdown
# Task Context: {original task description}

> Collected: {YYYY-MM-DD HH:MM}
> Files copied: {count}
> Search terms: {keyword1, keyword2, ...}
> Search hits: keyword={n} files, naming={n}, wiring={n}, shared={n}

## Index

| # | Copied | Original | Relevance |
|---|--------|----------|-----------|
| 1 | `breeding_plugin.dart` | `lib/plugins/breeding/breeding_plugin.dart` | Feature entry point |
| 2 | `breeding_tables.dart` | `lib/plugins/breeding/breeding_tables.dart` | Database schema |
| 3 | `breeding_repository.dart` | `lib/plugins/breeding/breeding_repository.dart` | Data access layer |
| 4 | `breeding_record_screen.dart` | `lib/plugins/breeding/breeding_record_screen.dart` | UI screen |
| ... | ... | ... | ... |

## Notes

- All originals are unmodified. These are copies.
- Prioritized by feature match, registration hits, and keyword density.
- Max 30 files. {n} additional files were omitted — see below if applicable.
```

**Relevance labels** (choose the best fit for each file):

| Label | What it describes |
|---|---|
| `Feature entry point` | Plugin registration file |
| `Database schema` | Tables file or generated `.g.dart` |
| `Data access layer` | Repository files |
| `UI screen` | Screen or page widget |
| `UI widget` | Reusable widget or section component |
| `Service / logic` | Service, utility, or business logic |
| `Registration / wiring` | plugins.dart, providers.dart, app.dart |
| `Shared infrastructure` | core/ files |
| `Theme / tokens` | Theme or design-token files |
| `Model / types` | Shared model or type definition |
| `Configuration` | Config or settings files |

If zero relevant files were found, still create the directory and write a
minimal README.md:

```markdown
# Task Context: {original task description}

> Collected: {YYYY-MM-DD HH:MM}
> Files copied: 0
> Search terms: {keywords}

## Notes

> No matching files found.
```

### Step 8 — Report

After writing, report:

- Output directory path: `temp/{slug}/`
- Number of files copied
- Search terms used
- Which search categories produced hits (keyword / naming / wiring / shared)
- One-line summary of what was collected

## Constraints

- Output directory: `temp/{slug}/` relative to the project root. Never write
  files outside this path.
- Max 30 files copied. If more are relevant, include the top 30 by priority
  score and list omitted files in the README.
- The model must **never** read copied files' contents. Use
  `output_mode: files_with_matches` on Grep and `Copy-Item` in PowerShell.
  Search C is the sole, bounded exception — exactly 2–4 small wiring files.
- Fire all searches in Step 3 as a single parallel batch. They share no
  dependencies.
- Overwrite existing `temp/{slug}/` without warning — `temp/` is gitignored
  and disposable.
- If zero relevant files are found, still create the directory and README
  with a "No matching files found" note. Do not skip writing.
