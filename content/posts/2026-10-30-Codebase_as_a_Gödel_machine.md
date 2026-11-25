---
title: Codebase as a Gödel machine
date: 2026-10-30
draft: true
tags:
  - deeplearning
  - RSI
  - harness
math: true
ShowToc: true
TocOpen: false
---
We are so back, after a long time. Inspired from [Gödel Machine](https://people.idsia.ch/~juergen/goedelmachine.html).

> I think this writing will be a running ledger.

I think coding harness should be opinionated with default skills available, so that people don't have to waste their time searching about skills and then bringing them to there harness. Well, most people don't even know that they should **own** the harness, what do I mean by owning their harness? I mean, think if you are using codex and your teammate is using antigravity or claude code, are their experience same? in the same codebase? just model changes, given that all are literally having same benchmark scores on terminal bench? No? why is that?

When you search this on internet, you will find benchmarks like

<figure style="text-align: center;">
  <img src="../../assets/2026-10-30-Codebase_as_a_Gödel_machine/file-20261031114305232.png" alt="Artificial Analysis Coding Agent Index v2.0 leaderboard comparing coding agents and models" style="max-width: 100%; height: auto;">
  <figcaption><strong>Fig. 1.</strong> Artificial Analysis Coding Agent Index v2.0 leaderboard comparing agent harnesses and models (source: <a href="https://artificialanalysis.ai/agents/coding-agents?routers=false">Artificial Analysis</a>).</figcaption>
</figure>

But you know what? I think this doesn't matter at all!
what a `Claude Code` harness can do vs what `OpenCode` can do? Okay, they do have different compaction strategy, they have different memory strategy or no memory at all, plan mode/build mode, etc. But this is "How well they generalise on unseen codebase".

If you are working on a codebase and thinking "Claude Code" will figure it out, ygmi.

Btw, this all started from a frustration of how bad `Gemini 3.8 Flash` performed on my tasks.

This is from Google's Antigravity CLI.

<figure style="text-align: center;">
  <img src="../../assets/2026-10-30-Codebase_as_a_Gödel_machine/file-20261030230847676.png" alt="Antigravity CLI session log showing Gemini 3.8 Flash repeatedly reading the same turn.py file" style="max-width: 100%; height: auto;">
  <figcaption><strong>Fig. 2.</strong> Screenshot of an <code>agy-cli</code> session with <code>gemini 3.8 flash high</code> repeatedly reading the same file slices.</figcaption>
</figure>

<figure style="text-align: center;">
  <img src="../../assets/2026-10-30-Codebase_as_a_Gödel_machine/file-20261030232033147.png" alt="CursorBench 4.0 score vs. average steps per task showing Gemini 3.8 Flash taking ~290+ steps" style="max-width: 100%; height: auto;">
  <figcaption><strong>Fig. 3.</strong> CursorBench 4.0 score vs. average steps per task, highlighting Gemini 3.8 Flash taking far more steps than peer models (source: <a href="https://x.com/eliebakouch/status/2098184670206664761">@eliebakouch on X</a>).</figcaption>
</figure>

<figure style="text-align: center;">
  <img src="../../assets/2026-10-30-Codebase_as_a_Gödel_machine/file-20261030232109439.png" alt="Post by ThePrimeagen noting Gemini 3.8 Flash repeatedly reading proxy.ts and log.ts" style="max-width: 100%; height: auto;">
  <figcaption><strong>Fig. 4.</strong> Observation of Gemini 3.8 Flash repeatedly reading the same two files in a loop (source: <a href="https://x.com/ThePrimeagen/status/2095565354726502683">@ThePrimeagen on X</a>).</figcaption>
</figure>

> after some digging I found that this was not a harness problem, it was "3.8 flash" which was having cracks in its weights. 
> 
> I think the most simple way is to make post training RL to "never read those lines which are already in context and read in the same tool call?", but I am not sure, why did "Gemini 3.8 Flash" a big model was having a [doomloop](https://www.liquid.ai/blog/antidoom) problem.


So, I was using Antigravity IDE's sidechat for AI coding, until I came to know that IDE is largely outdate and there where no features like subagent June/July 2026 -- when subagent was already like a basic need for delegating tasks and preserve the context window.

Then I came to know "people use CLIs" and moved away from that side chat! and then found that AGY the cli still does the same (the harness for both `agy-ide` and `agy-cli` were different at the moment) `agy-cli` supported subagent, etc, but ide did not.

But soon I realised that people also moved away from [CLIs](https://x.com/Yuchenj_UW/status/2106435001340621147) also and they use the Codex / Claude Desktop as their primary driver.

So thats the SOTA Coding agents right? I switched to Codex. Still there are 2 problems that I felt needs to be solved:
a. the searching trajectory of coding agent was stupid, its like "read read read read" it starts every conversation with increasing compute (test time compute), it used tools to read the code chunks, files and everything it things it was necessary.

The problem, sometime that trajectory was clean, input sequence -> tool use (one `ls`, then one read) -> tool use (diff) -> done; but that only worked on simple coding problems, where one-two file need to be changed. What if you asked the model an architectural problem or try to implement new feature. they do perform a research itself and then for actual "diffs" generating time, they already have 100K+ tokens in the context. Now we know it faces what we call "[Context Rot](https://www.trychroma.com/research/context-rot)"

<figure style="text-align: center;">
  <img src="../../assets/2026-10-30-Codebase_as_a_Gödel_machine/file-20261031114554500.png" alt="Repeated Words task performance degrading as input token length increases across Claude Sonnet 4, GPT-4.1, Qwen3-32B, and Gemini 2.5 Flash" style="max-width: 100%; height: auto;">
  <figcaption><strong>Fig. 5.</strong> Context rot benchmark on the Repeated Words task: accuracy degrades sharply as input length grows toward 10k tokens (source: <a href="https://www.trychroma.com/research/context-rot">Chroma Research</a>).</figcaption>
</figure>

So, at the time of actual work, you are working on a place where the llm is not at its peak performance? Nice. It helps Labs, because their goal is to push:

[**long-horizon knowledge work tasks**](https://x.com/ArtificialAnlys/status/2067744637155226101?lang=en)

your complete work -- will help them, with us suffering the pain of saying: "Yo wth man, you choose the wrong place" or "dude you messing with the signature of the function, which is globally clean" or "stop patch working dude".

So, the clear first problem is something more fundamental, the harness they provide "Codex", altho its a "Coding agent", so "what can we do to reduce the intake of token?" 

If what you say something and within the first 8k-10k tokens itself the search agent will know "where to make the changes" exactly, hmm? I mean search?

Search!

The problem is search itself!

See:

<figure style="text-align: center;">
  <img src="../../assets/2026-10-30-Codebase_as_a_Gödel_machine/file-20261030233533416.png" alt="Post by Aravind Srinivas: The recipe: 1. Solve Search. 2. Use it to solve everything else." style="max-width: 100%; height: auto;">
  <figcaption><strong>Fig. 6.</strong> Aravind Srinivas on why solving search unlocks everything else (source: <a href="https://x.com/AravSrinivas/status/1908249429452480549">@AravSrinivas on X</a>).</figcaption>
</figure>

Right?

how does the coding agent search? grep? ls? 'search tool' because computers are different from how humans intake information, right? Right, grep is a tool like we have eyes in our head to see the screen! the fundamentals are the same.

think when you want to search where is that piece of code used, what do you use? "cmd + click" on the function in the IDE? right? that works on [AST](https://en.wikipedia.org/wiki/Abstract_syntax_tree) 

<figure style="text-align: center;">
  <img src="../../assets/2026-10-30-Codebase_as_a_Gödel_machine/file-20261031120028952.png" alt="IDE go-to-definition and symbol outline view powered by Abstract Syntax Tree indexing" style="max-width: 100%; height: auto;">
  <figcaption><strong>Fig. 7.</strong> AST-backed symbol navigation and definition lookup in an IDE.</figcaption>
</figure>

How about we give the model, search AST itself?

Part 2/N will come.


## References
1. Schmidhuber, J. [Gödel Machines](https://people.idsia.ch/~juergen/goedelmachine.html).
2. [Artificial Analysis Coding Agent Index](https://artificialanalysis.ai/agents/coding-agents?routers=false)
3. [Context Rot — Chroma Research](https://www.trychroma.com/research/context-rot)
4. [Anti-Doom — Liquid AI](https://www.liquid.ai/blog/antidoom)
5. [Abstract Syntax Tree — Wikipedia](https://en.wikipedia.org/wiki/Abstract_syntax_tree)
6. [@eliebakouch](https://x.com/eliebakouch/status/2098184670206664761), [@ThePrimeagen](https://x.com/ThePrimeagen/status/2095565354726502683), and [@AravSrinivas](https://x.com/AravSrinivas/status/1908249429452480549) on X.
