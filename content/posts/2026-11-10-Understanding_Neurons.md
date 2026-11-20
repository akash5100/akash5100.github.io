---
title: "Understanding Neurons"
date: 2026-11-10
draft: true
tags:
  - "deeplearning"
  - "interpretability"
math: true
ShowToc: true
TocOpen: false
---

Reading [Cammarata, N., 2026. Neural Networks Are Already Clean. Goodfire](https://already-clean.goodfire.com/#prior-work) and logging things that I understand while reading the essay by [Nick](https://x.com/nickcammarata).


For your opening paragraph right under your intro line, start by stating the **core shift in your own mental model**—for example, talking into your mic about:
- What you previously assumed about polysemanticity and SAEs before reading [Neural Networks Are Already Clean](https://already-clean.goodfire.com/#prior-work).
- The central realization from the essay: that the interpretability field mistook architectural flaws in InceptionV1 and weak microscope tools for a fundamental law of neural networks (superposition).


1. **What is superposition at a fundamental level?**
	- _Prompt to talk through:_ Explain the original hypothesis (packing more concepts than neurons using sparsity and near-orthogonal vectors) and why people thought neurons were polysemantic.

2. **The Two Approaches to Interpretability & The InceptionV1 Detour**
	- _Prompt to talk through:_ Contrast the first method (direct "normal science" on raw neurons and circuits) with the second method (training Sparse Autoencoders to untangle a supposedly knotted network). Explain how Nick went back to the first method and tested models across a 300× scale range, finding coarse-to-fine concepts rather than tangled knots.

3. **Why InceptionV1 "Overflowed" & How Modern Architectures Fixed It**
	- _Prompt to talk through:_ Break down why InceptionV1's late layers looked like garbage (no residual stream, ReLU clipping, activation/gradient overflow at the softmax bottleneck) versus how modern architectures (ConvNeXt with Residual Connections, LayerNorm, and SwiGLU) make 99–100% of late-layer neurons naturally legible.

4. **Refuting the 2019 "Smoking Gun" Circuit & The 2023 LLM Audits**
    - _Prompt to talk through:_ Explain how the original 2019 _Zoom In_ car-into-dog superposition circuit turned out to be unread downstream (just shared pose/shape generalization), and how modern frontier LLMs (Qwen3-32B, Kimi K3) flipped from 0–1.7% interpretable in 2023 to ~90–97% clean today.

5. **Activation vs. Causal Usefulness (RelP / Relevance Patching)**
    - _Prompt to talk through:_ Explain the difference between _when a neuron fires_ (top-k activations, which include harmless noise) and _when it actually matters_ to the output logits using Relevance Patching (RelP / LRP conservation rules through non-linearities).

6. **Recursive Generalization vs. Superposition**
    - _Prompt to talk through:_ Describe how neurons actually grow during training—branching out locally like a tree (`"iy"` $\to$ `"diy"` $\to$ `"do it yourself"`) rather than randomly folding unrelated things together—making generalization fractal.

7. **Why the 2023 vs. 2026 Gap Happened & The "Crossword" Momentum (SwiGLU Poles & Motifs)**
    - _Prompt to talk through:_ Explain why 2023 tools failed (simulation scores, missing the comma summary motif) and how SwiGLU's bipolar structure works technically (positive pole, negative pole as an active gate, and the double-negative leak where $\text{gate} < 0$ and $\text{up} < 0$ multiply to a fake positive). Wrap up with how solving surrounding circuits constrains the rest of the network like a crossword puzzle.



# References
- [Cammarata, N., 2026. Neural Networks Are Already Clean. Goodfire](https://already-clean.goodfire.com/#prior-work) 
- 