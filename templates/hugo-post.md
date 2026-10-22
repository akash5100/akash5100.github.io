<%*
const title = await tp.system.prompt("Post title");
if (!title || !title.trim()) { throw new Error("Post title is required"); }

const tagsRaw = (await tp.system.prompt("Tags (comma separated)", "deeplearning")) ?? "";
const date = tp.date.now("YYYY-MM-DD");
const slug = title.trim().replace(/\s+/g, "_");
const name = `${date}-${slug}`;
const tags = tagsRaw.split(",").map((t) => t.trim()).filter(Boolean);

// Hugo asset folder for this post, matches Custom Attachment Location's pattern.
// assets/ sits at the vault root and is mounted at /assets/ by hugo.yaml.
try { await app.vault.createFolder(`assets/${name}`); } catch (e) { /* already exists */ }

// Rename + move the new note into content/posts/<date>-<slug>.md
await tp.file.move(`/content/posts/${name}`);
-%>
---
title: <% JSON.stringify(title.trim()) %>
date: <% date %>
tags:
<%* for (const t of tags) { -%>
  - <% JSON.stringify(t) %>
<%* } -%>
math: true
ShowToc: true
TocOpen: false
---
