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
![](../../assets/2026-10-30-Codebase_as_a_Gödel_machine/file-20261031114305232.png)
src: https://artificialanalysis.ai/agents/coding-agents?routers=false

But you know what? I think this doesn't matter at all!
what a `Claude Code` harness can do vs what `OpenCode` can do? Okay, they do have different compaction strategy, they have different memory strategy or no memory at all, plan mode/build mode, etc. But this is "How well they generalise on unseen codebase".

If you are working on a codebase and thinking "Claude Code" will figure it out, ygmi.

Btw, this all started from a frustration of how bad `Gemini 3.8 Flash` performed on my tasks.

This is from Google's Antigravity CLI.

 ![](../../assets/2026-10-30-Codebase_as_a_Gödel_machine/file-20261030230847676.png)
 src: my screenshot of `agy-cli` with `gemini 3.8 flash high`

![](../../assets/2026-10-30-Codebase_as_a_Gödel_machine/file-20261030232033147.png)
https://x.com/eliebakouch/status/2098184670206664761

![](../../assets/2026-10-30-Codebase_as_a_Gödel_machine/file-20261030232109439.png)
https://x.com/ThePrimeagen/status/2095565354726502683

> after some digging I found that this was not a harness problem, it was "3.8 flash" which was having cracks in its weights. 
> 
> I think the most simple way is to make post training RL to "never read those lines which are already in context and read in the same tool call?", but I am not sure, why did "Gemini 3.8 Flash" a big model was having a [doomloop](https://www.liquid.ai/blog/antidoom) problem.


So, I was using Antigravity IDE's sidechat for AI coding, until I came to know that IDE is largely outdate and there where no features like subagent June/July 2026 -- when subagent was already like a basic need for delegating tasks and preserve the context window.

Then I came to know "people use CLIs" and moved away from that side chat! and then found that AGY the cli still does the same (the harness for both `agy-ide` and `agy-cli` were different at the moment) `agy-cli` supported subagent, etc, but ide did not.

But soon I realised that people also moved away from [CLIs](https://x.com/Yuchenj_UW/status/2106435001340621147) also and they use the Codex / Claude Desktop as their primary driver.

So thats the SOTA Coding agents right? I switched to Codex. Still there are 2 problems that I felt needs to be solved:
a. the searching trajectory of coding agent was stupid, its like "read read read read" it starts every conversation with increasing compute (test time compute), it used tools to read the code chunks, files and everything it things it was necessary.

The problem, sometime that trajectory was clean, input sequence -> tool use (one `ls`, then one read) -> tool use (diff) -> done; but that only worked on simple coding problems, where one-two file need to be changed. What if you asked the model an architectural problem or try to implement new feature. they do perform a research itself and then for actual "diffs" generating time, they already have 100K+ tokens in the context. Now we know it faces what we call "[Context Rot](https://www.trychroma.com/research/context-rot)"

![](../../assets/2026-10-30-Codebase_as_a_Gödel_machine/file-20261031114554500.png)
https://www.trychroma.com/research/context-rot

So, at the time of actual work, you are working on a place where the llm is not at its peak performance? Nice. It helps Labs, because their goal is to push:

[**long-horizon knowledge work tasks**](https://x.com/ArtificialAnlys/status/2067744637155226101?lang=en)

your complete work -- will help them, with us suffering the pain of saying: "Yo wth man, you choose the wrong place" or "dude you messing with the signature of the function, which is globally clean" or "stop patch working dude".

So, the clear first problem is something more fundamental, the harness they provide "Codex", altho its a "Coding agent", so "what can we do to reduce the intake of token?" 

If what you say something and within the first 8k-10k tokens itself the search agent will know "where to make the changes" exactly, hmm? I mean search?

Search!

The problem is search itself!

See:

![](../../assets/2026-10-30-Codebase_as_a_Gödel_machine/file-20261030233533416.png)
https://x.com/AravSrinivas/status/1908249429452480549

Right?

how does the coding agent search? grep? ls? 'search tool' because computers are different from how humans intake information, right? Right, grep is a tool like we have eyes in our head to see the screen! the fundamentals are the same.

think when you want to search where is that piece of code used, what do you use? "cmd + click" on the function in the IDE? right? that works on [AST](https://en.wikipedia.org/wiki/Abstract_syntax_tree) 

![](../../assets/2026-10-30-Codebase_as_a_Gödel_machine/file-20261031120028952.png)

How about we give the model, search AST itself?

Part 2/N will come.