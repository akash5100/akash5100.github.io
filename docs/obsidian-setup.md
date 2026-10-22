# Writing posts in Obsidian

One click makes a post. Dropping an image puts it where Hugo expects it, and it is visible in both
Obsidian and the published site.

## One-time setup

```bash
./scripts/install-obsidian-plugins.sh
```

Then open Obsidian once: **Settings → Community plugins → turn off Restricted mode**. The four
plugins load and a **New post** button (file-plus icon) appears in the left ribbon.

Reload the app after running the script (`Cmd+R`) so already-running plugins pick up the settings
it writes.

Everything the script writes lives in `.obsidian/`, which is gitignored — the vault config is local
to a machine, the automation is versioned.

## Publishing a post

Click **New post** → it asks for a title and tags → it creates:

```
content/posts/2026-10-22-My_Post_Title.md    <- the note, opened for writing
assets/2026-10-22-My_Post_Title/             <- its image folder, already created
```

Front matter is filled in to match the rest of the blog:

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

## Images

Drag or paste an image into the note body. It is saved to `assets/<note name>/`, renamed to a
slug (`Screenshot 2026-10-22 at 11.16.24 AM.png` → `Screenshot-2026-10-22-at-11.16.24-AM.png`), and
Obsidian inserts a normal relative markdown link:

```markdown
![image](../../assets/2026-10-22-My_Post_Title/Screenshot-2026-10-22-at-11.16.24-AM.png)
```

That one path works everywhere:

- **In Obsidian** — it resolves from `content/posts/` up two levels to the `assets/` folder.
- **On the site** — the post lives at `/posts/<slug>/`, also two levels deep, so the browser
  resolves the same `../../` to `/assets/<note name>/<file>.png`.

`hugo.yaml` mounts the vault-root `assets/` folder as `static/assets`, so Hugo publishes those files
at the same `/assets/...` URL. Nothing rewrites paths at publish time.

Why the images live in a vault-root `assets/` folder rather than `static/assets/`: a
`/assets/...` link is vault-absolute in Obsidian, and the vault root has no `assets/` otherwise, so
the image would show as a broken link inside Obsidian even though the site worked.

## Settings the script writes

| Plugin | Setting | Value |
|---|---|---|
| Obsidian core | `useMarkdownLinks` | `true` (wikilinks can't be rendered by Hugo) |
| Obsidian core | `newLinkFormat` | `relative` |
| Custom Attachment Location | `shouldFollowObsidianAttachmentLocation` | `false` (lets the pattern below win) |
| Custom Attachment Location | `attachmentFolderPath` | `assets/{{noteFileName}}` |
| Custom Attachment Location | `generatedAttachmentFileName` | `{{originalAttachmentFileName:{slugify:true}}` |
| Custom Attachment Location | `attachmentRenameMode` | `All` (no spaces in file names) |
| Custom Attachment Location | `markdownUrlFormat` | empty — Obsidian's own link generator is used |
| Templater | `templates_folder` | `templates` |
| Commander | `leftRibbon` | one entry → `templater-obsidian:create-new-note-from-template` |

`markdownUrlFormat` is deliberately empty. When set, the plugin rewrites the link Obsidian is about
to insert, and that rewriting is skipped if anything in it fails — which leaves the image saved but
no link in the note.

`Custom Attachment Location` needs `Advanced Rename and Delete Handler` installed; it refuses to
load without it. The script installs both.

## Conventions

- Note: `content/posts/<date>-<Title_With_Underscores>.md` → page at `/posts/<date>-<title_lowercased>/`
- Assets: `assets/<same name as the note>/`
- Posts migrated from Jekyll keep their undated folders (`assets/Transformers/`) and their `/blog/...`
  aliases; only new posts follow the dated convention.

Images are Git LFS-tracked by `.gitattributes` anywhere in the repo, so new drops are handled
automatically; the deploy workflow runs `git lfs checkout`.

## If something misbehaves

- **Image saved, no link inserted** — the drop landed somewhere that isn't the editor body (reading
  view, tab header, file explorer), or the plugin still has an old `markdownUrlFormat`. Reload with
  `Cmd+R`; if it persists, check the setting is empty.
- **Image saved but shows as a broken link in Obsidian** — the note is linking to `/assets/...`
  rather than `../../assets/...`. Check `newLinkFormat` is `relative` and `useMarkdownLinks` is on.
- **The note lands as `Untitled`** — the Templater template moves itself, and an older Templater can
  lose that rename. Update Templater, or move the leading `<%* ... %>` block to the end of
  `templates/hugo-post.md`.
- **No ribbon button** — Commander isn't loaded; check Restricted mode is off. As a fallback bind a
  hotkey to `Templater: Create new note from template`.
- **Obsidian feels slow** — exclude `public/`, `resources/` and `node_modules/` from indexing:
  Settings → Files and links → Excluded files.

## Without Obsidian

Nothing here is required. A post is a Markdown file with front matter in `content/posts/`, plus a
folder in `assets/` if it needs images.
