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
draft: true
tags:
<%* for (const t of tags) { -%>
  - <% JSON.stringify(t) %>
<%* } -%>
math: true
ShowToc: true
TocOpen: false
---

## Abstract

<!-- 2-3 sentence executive summary of the core thesis, empirical discovery, or architectural paradigm. -->

## Motivation

<!-- Formalize the problem statement, baseline bottlenecks, and mathematical formulation. -->

## Method

<!-- System mechanics, algorithmic pseudocode, context loops, and architectural diagrams. -->

## Empirical Results

<!-- Experimental benchmarks, throughput numbers, ablation tables, and scaling graphs. -->

## Future Challenges

<!-- Known failure modes, trade-offs, and open research directions. -->

## Citation

Please cite this work as:

> Verma, Akash. "<% title.trim() %>". *Akash's Blog* (<% tp.date.now("MMM YYYY") %>).

```bibtex
@article{verma<% tp.date.now("YYYY") %><% slug.toLowerCase().replace(/[^a-z0-9]/g, "") %>,
  title   = {<% title.trim() %>},
  author  = {Verma, Akash},
  journal = {akash5100.github.io},
  year    = {<% tp.date.now("YYYY") %>},
  month   = {<% tp.date.now("MMMM") %>},
  url     = {https://akash5100.github.io/posts/<% name.toLowerCase() %>/}
}
```

## Appendix

<!-- Detailed cluster topology, hyperparameters, prompt templates, or raw benchmark data. -->

## References

1. 
