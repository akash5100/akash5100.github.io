# Writing posts in Obsidian

One click makes a post. Dropping an image puts it where Hugo expects it.

## One-time setup

```bash
./scripts/install-obsidian-plugins.sh
```

Then open Obsidian once: **Settings → Community plugins → turn off Restricted mode**. The four
plugins load and a **New post** button (file-plus icon) appears in the left ribbon.

The script writes everything into `.obsidian/`, which is gitignored — the vault config is local,
the automation is here.

## Publishing a post

Click **New post** → it asks for a title and tags → it creates:

```
content/posts/2026-10-22-My_Post_Title.md      <- the note, opened for writing
static/assets/2026-10-22-My_Post_Title/        <- its image folder, already created
```

The front matter is filled in to match the rest of the blog:

```yaml
---
title: "My Post Title"
date: 2026-10-22
tags:
  - "deeplearning"
math: true
ShowToc: true
TocOpen: false
---
```

Write normally. `##` headings feed the automatic table of contents, `$$...$$` and `$...$` render
through KaTeX.

## Images

Drag or paste an image into the note. It is saved to `static/assets/<note name>/` and the inserted
link is `/assets/<note name>/<image>.png`, which is the URL Hugo serves it from.

That link is not Obsidian's default: Hugo serves `static/` at the site root, so a vault-relative
link like `static/assets/...` would render broken. Two settings carry this:

| Plugin | Setting | Value |
|---|---|---|
| Custom Attachment Location | `shouldFollowObsidianAttachmentLocation` | off (lets the pattern below win) |
| Custom Attachment Location | `attachmentFolderPath` | `static/assets/{{noteFileName}}` |
| Custom Attachment Location | `markdownUrlFormat` | `/assets/{{noteFileName}}/{{generatedAttachmentFileName}}.{{attachmentFileExtension}}` |
| Custom Attachment Location | `attachmentRenameMode` | `Only pasted images` (screenshots get names, dragged files keep theirs) |
| Templater | `templates_folder` | `templates` |
| Commander | `leftRibbon` | one entry → `templater-obsidian:create-new-note-from-template` |

`Custom Attachment Location` needs `Advanced Rename and Delete Handler` installed; it refuses to
load without it. The script installs both.

## URLs and names

- Note name: `<date>-<Title_With_Underscores>` → page at `/posts/<date>-<title_with_underscores>/`
- Assets: `static/assets/<same name as the note>/`
- Posts migrated from Jekyll keep their undated asset folders (`static/assets/Transformers/`) and
  their `/blog/...` aliases; only new posts follow the dated convention.

Images are Git LFS-tracked by `.gitattributes` anywhere in the repo, so new drops are handled
automatically; the deploy workflow runs `git lfs checkout`.

## If something misbehaves

- **The note lands as `Untitled`** — the Templater template moves itself, and an older Templater
  can lose that rename. Update Templater, or move the leading `<%* ... %>` block to the end of
  `templates/hugo-post.md`.
- **Images go to the vault root** — `shouldFollowObsidianAttachmentLocation` got re-enabled (a
  plugin update can reset it). Turn it off again.
- **Images render as broken links on the site** — `markdownUrlFormat` was cleared. Re-run the
  install script to rewrite it.
- **No ribbon button** — Commander isn't loaded yet; check Restricted mode is off. As a fallback
  bind a hotkey to `Templater: Create new note from template`.
- **Obsidian feels slow** — exclude `public/` and `resources/` from indexing: Settings → Files and
  links → Excluded files.

## Without Obsidian

Nothing here is required. A post is just a Markdown file with front matter in `content/posts/`
plus a folder in `static/assets/` if it needs images.
