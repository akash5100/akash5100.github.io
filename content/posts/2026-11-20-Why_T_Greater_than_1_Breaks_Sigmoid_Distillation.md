---
title: Why T > 1 Breaks Sigmoid Distillation
date: 2026-11-25
tags:
  - deeplearning
  - distillation
  - training-dynamics
math: true
ShowToc: true
TocOpen: false
---
This started as a practical production problem. I needed to migrate a multi-label [Locked-Image Tuning (LiT)](https://arxiv.org/abs/2111.07991) classifier head from a pretrained [SigLIP 2](https://arxiv.org/abs/2502.14786) backbone onto a fine-tuned SigLIP 2 checkpoint already indexing images in production, so distilling the old head into a new one on top of the frozen production backbone was the cleanest way to avoid retraining from scratch. Following [Hinton et al. (2015)](https://arxiv.org/abs/1503.02531), I started with the standard distillation temperature $T = 4.0$: in Softmax distillation, raising $T$ exposes the teacher's uncertainty across competing classes, giving the student richer signal than hard labels. Because each image could have multiple labels at once, the classifier used independent Sigmoid outputs with Binary Cross-Entropy (BCE) loss, and distilling with $T = 4.0$ hurt performance every time instead of helping.

My first explanation was simple: dividing large negative teacher logits by $T = 4.0$ pushes absent-class probabilities up toward 0.5, which should flood the student with false positives. When I built a controlled public reproduction on [MS-COCO 2017](https://arxiv.org/abs/1405.0312) to isolate why $T = 1.0$ worked while $T = 4.0$ failed, that explanation turned out to be wrong. The student wasn't producing false alarms; it was losing Recall because absent classes hijacked over 90% of the gradient budget. In this post, I walk through the intuition, the falsified hypothesis, and a 7-temperature sweep ($T = 0.5$ to $6.0$) showing two opposite failure modes around $T = 1.0$. All code and reproduction scripts are open-sourced in [trainbench](https://github.com/akash5100/trainbench/tree/main/experiments/sigmoid_distill).

## Softmax vs. Sigmoid Under Temperature Scaling

In [Hinton et al. (2015)](https://arxiv.org/abs/1503.02531), knowledge distillation was built around Softmax. Most people write `softmax(x)` with a single input because $T = 1.0$ is baked in by default, whereas temperature-scaled softmax divides the logits by $T$ first, normalizing $\exp(x_i / T) / \sum_j \exp(x_j / T)$.

You can think of temperature $T > 1$ in Softmax as a **magnifying glass** over the losing classes in a categorical probability distribution. Suppose a model predicts among three classes: `dog`, `wolf`, and `car`. At $T = 1.0$, `dog` takes 99.97% of the probability mass, while `wolf` (0.03%) and `car` (0.00003%) are both crushed near zero. Even though `dog` is clearly the winner, the teacher still thinks the image looks much more like a `wolf` than a `car`, which reflects real-world similarity (what Hinton called *dark knowledge*). Raising the temperature to $T = 4.0$ smooths out the distribution (86.3% `dog`, 11.7% `wolf`, 2.0% `car`) so the student can actually see and learn that uncertainty across competing classes:

```python
import torch


def softmax(x, t=1.0):
    x = x - x.max()
    e = torch.exp(x / t)
    return e / e.sum()


logits = torch.tensor([10.0, 2.0, -5.0])  # eg: [dog, wolf, car]
softmax(logits, t=1.0)  # tensor([9.9966e-01, 3.3535e-04, 3.0580e-07])
softmax(logits, t=4.0)  # tensor([0.8630, 0.1168, 0.0203])
```

### Why Sigmoid Behaves Differently

Softmax is built for $N$ mutually exclusive classes competing with each other so that all probabilities sum to 1. Sigmoid is mathematically a two-way Softmax (a special case with just two classes: yes vs. no, such as `dog` vs. `no dog`), applied **independently** to every class:

$$\sigma(x / T) = \frac{1}{1 + e^{-x / T}}$$

Raw logits coming out of a neural network are just unbounded numbers (negative means likely absent, positive means likely present) that are hard to understand until an activation layer squashes them into $(0, 1)$. The minus sign in $e^{-x/T}$ makes large positive logits approach 1 and large negative logits approach 0.

Because Sigmoid has no rival classes competing under a sum-to-1 cap, temperature $T$ does something completely different here. Instead of acting like a magnifying glass over similar rival classes, $T$ acts like a **confidence or error tolerance knob** on a single 1D curve anchored at $(0, 0.5)$. As $T$ approaches 0, the curve becomes a sharp step function; as $T$ increases above 1, the curve flattens out toward 50%.

<figure style="text-align: center;">
  <img src="/assets/2026-11-20-Why_T_Greater_than_1_Breaks_Sigmoid_Distillation/sigmoid_temperature_curves.png" alt="Sigmoid Under Temperature Scaling" style="max-width: 100%; height: auto;">
  <figcaption><strong>Fig. 1.</strong> Temperature scaling on an independent Sigmoid curve, $\sigma(x / T)$, anchored at $(0, 0.5)$. Raising $T$ above 1.0 flattens the curve and lifts a confident absent logit ($x = -4.0$) from 1.8% at $T = 1.0$ to 26.9% at $T = 4.0$ and 33.9% at $T = 6.0$.</figcaption>
</figure>

Look at what that flattening does to a confident absent class with logit $x = -4.0$. At $T = 1.0$, the teacher target is 0.018 (1.8%). At $T = 4.0$, that same absent class jumps to 0.269 (26.9%), and at $T = 6.0$ it reaches 0.339 (33.9%). In a sparse multi-label dataset like MS-COCO (80 classes, where roughly 77 classes are absent in any given image), there is no sum-to-1 cap to hold them down, so raising $T$ pushes all ~77 absent-class targets up toward 0.5 independently at the same time.

<figure style="text-align: center;">
  <img src="/assets/2026-11-20-Why_T_Greater_than_1_Breaks_Sigmoid_Distillation/sigmoid_temperature_sweep.gif" alt="Sigmoid Temperature Sweep Animation" style="max-width: 100%; height: auto;">
  <figcaption><strong>Fig. 2.</strong> Continuous temperature sweep from $T = 0.5$ to $T = 6.0$ (compared against the dashed $T = 1.0$ reference), showing how raising $T$ pulls both absent ($x = -4.0$) and present ($x = +4.0$) logits symmetrically toward 0.5.</figcaption>
</figure>


### Why $T = 4.0$ Training Loss Plateaus at ~1.20 (The Teacher Entropy Floor)

On the MS-COCO training runs, $T = 4.0$ plateaus way higher than $T = 1.0$ (~1.20 vs. ~0.03).

<figure style="text-align: center;">
  <img src="/assets/2026-11-20-Why_T_Greater_than_1_Breaks_Sigmoid_Distillation/wandb_epoch_loss_floor.png" alt="MS-COCO Training Loss Plateaus (Teacher Entropy Floor)" style="max-width: 100%; height: auto;">
  <figcaption><strong>Fig. 3.</strong> Step-level training loss (BCE, 150-step rolling mean over raw mini-batch jitter) on MS-COCO across $T = 1.0$ and $T = 4.0$. Even when the student matches the teacher, $T = 4.0$ plateaus at ~1.20 ($\alpha = 1.0$), ~1.08 ($\alpha = 0.9$), and ~0.62 ($\alpha = 0.5$) due to the teacher entropy floor.</figcaption>
</figure>

At first glance that looks like a broken run or a loss explosion, and it is easy to mix up $\alpha$ and $T$ here. $\alpha$ only controls how much weight goes to the teacher versus ground truth; $T$ is what changes the teacher's targets themselves. As $T$ increases above 1, the flattened sigmoid turns crisp binary teacher targets into uncertain mid-range probabilities like 0.3 or 0.45, feeding the teacher's own uncertainty (entropy) straight into the Binary Cross-Entropy loss:

$$\text{BCE}(q, p) = -\big(q \log p + (1 - q) \log(1 - p)\big)$$

where $q$ is the teacher's probability and $p$ is the student's predicted probability.

That ~1.20 plateau is **not** a broken run or the student failing to fit the teacher. Even a **perfect clone** of the teacher ($p = q$) hits that exact same wall, because soft targets near 0.3 to 0.45 carry nonzero entropy (~0.30 average teacher entropy across 80 classes, multiplied by the $T = 4.0$ scaling in `sigmoid_kd.py`, equals ~1.20). You can see the floor scale linearly with $\alpha$ across runs (~1.20 at $\alpha = 1.0$, ~1.08 at $\alpha = 0.9$, and ~0.62 at $\alpha = 0.5$). The real problem is not that high loss floor on the training chart, but what those softened targets do to the gradients: in Softmax distillation, teacher entropy across competing classes carries helpful dark knowledge, whereas in sparse independent Sigmoid, pushing ~77 absent classes into that uncertain mid-range creates much larger absent-class gradients and forces the optimizer to spend most of its steps chasing absent-class noise, which we will measure directly below.

<details>
<summary><strong>Primer: Activations, <code>-log(p)</code>, BCE, and KL Divergence</strong></summary>

A few fundamentals worth keeping straight before looking at the benchmark results:

**Why Softmax instead of `argmax`, and why `x - x.max()`:**
A neural network is a stack of matrix multiplications that outputs raw logits. Hard `argmax` acts like an on/off switch (1 for the winner, 0 for everything else), which kills gradients because its derivative is zero almost everywhere. Softmax gives us a smooth curve instead. Inside `exp()`, subtracting `x.max()` shifts the largest logit down to 0 so `exp()` never overflows, while leaving the output probabilities completely unchanged. (Writing `x.max() - x` would flip the distribution, and subtracting after `exp()` misses the point because the overflow has already happened.)

**Activation layer vs. the actual grader ($-\log p$):**
Softmax and Sigmoid are not loss functions; they are just activation layers that turn raw logits into probabilities. The actual grader (the teacher scoring the model) is the negative logarithm, $-\log(p)$. This choice comes from Claude Shannon's Information Theory (1948) and connects to Kolmogorov complexity: minimizing $-\log(p)$ is literally optimal data compression. Taking logs turns products of probabilities across a sequence into sums ($\log(p_1 p_2 p_3) = \log p_1 + \log p_2 + \log p_3$), which stops tiny probabilities from underflowing to zero and cancels the `exp` inside Softmax for clean gradients. Because probabilities live in $(0, 1]$, their logs are negative, so the minus sign flips them positive into a clean penalty curve:
- When the model is confident on the true label ($p = 0.99$), $-\log(0.99) \approx 0.01$ (almost zero penalty).
- When the model puts tiny probability on the truth ($p = 0.0001$), $-\log(0.0001) \approx 9.21$ (a steep cliff of punishment).

**Cross-Entropy, BCE, and NLL in plain English:**
- **Cross-Entropy** ($-\sum_i y_i \log p_i$) is the general parent: a weighted sum of $-\log(p)$ across all $K$ classes (which is a weighted average whenever the target probabilities sum to 1).
- **Negative Log-Likelihood (NLL)** is the hard-label special case where one-hot 0s switch off every non-target class, leaving only $-\log(p_{\text{true}})$. Because Softmax is a competition, pushing up the true class automatically pushes down the other classes in the denominator.
- **Binary Cross-Entropy (BCE)** is the $K = 2$ version applied independently to every class (`cat` yes/no, `dog` yes/no, `wolf` yes/no). In plain English, soft BCE is just a weighted average of both outcomes (like a 20% rain / 80% no-rain forecast): $q(-\log p) + (1 - q)(-\log(1 - p))$.

**KL Divergence and the entropy floor:**
KL Divergence measures how far the student's distribution is from the teacher's, pulling the student's predictions toward the teacher's. Its exact link to BCE ties everything together:

$$\text{KL}(q \,\|\, p) = \text{BCE}(q, p) - H(q)$$

KL Divergence is literally BCE minus the teacher's constant entropy floor $H(q)$. That is why KL drops all the way to 0.0 when the student perfectly matches the teacher ($p = q$), whereas BCE stops at $H(q)$. Because $H(q)$ never changes with the student's weights, both give the exact same gradients during training.

</details>



## Controlled Benchmark: MS-COCO 2017

To isolate the effect of temperature on a clean public benchmark, I reproduced the setup on [MS-COCO 2017](https://arxiv.org/abs/1405.0312) (80 object classes, 118,287 training images, 5,000 validation images, with ~96.4% negative sparsity, meaning ~77 of 80 labels are absent per image). Both the teacher (`google/siglip2-so400m-patch14-384`) and the student (`google/siglip2-base-patch16-256`) keep their vision backbones completely frozen, and only a lightweight 2-layer multi-label head is trained for 10 epochs (AdamW, `lr = 1e-3`, batch size 64, mixed precision). All training and evaluation scripts live in [trainbench](https://github.com/akash5100/trainbench/tree/main/experiments/sigmoid_distill).

The distillation loss (`SigmoidDistillationLoss`) mixes the teacher's soft Sigmoid targets with the hard ground-truth labels using a weight $\alpha$ and temperature $T$:

$$
\begin{aligned}
\mathcal{L}_{\text{KD}} &= T \cdot \text{BCE}\!\left(\sigma(t / T),\, \sigma(s / T)\right) \\
\mathcal{L}_{\text{GT}} &= \text{BCE}\!\left(y,\, \sigma(s)\right) \\
\mathcal{L} &= \alpha \cdot \mathcal{L}_{\text{KD}} + (1 - \alpha) \cdot \mathcal{L}_{\text{GT}}
\end{aligned}
$$

where $t$ and $s$ are the teacher and student logits, and $y \in \{0, 1\}^{80}$ are the ground-truth labels.

I started with a controlled $\alpha \times T$ grid, sweeping $\alpha \in \{0.0, 0.5, 0.9, 1.0\}$ against $T = 1.0$ vs. $T = 4.0$. At every teacher weight, changing **only** $T$ from 1.0 to 4.0 dropped validation Macro-F1 by ~1.1% to 1.2% (**Table 1**, **Fig. 4**). Setting $\alpha = 1.0$ (100% teacher, 0% ground truth) removes the ground-truth term completely so we can see how the student learns from pure soft Sigmoid targets. Note also that scaling $\mathcal{L}_{\text{KD}}$ by $T$ instead of Hinton's $T^2$ does not change the $\alpha = 1.0$ results: with no ground-truth term to balance against, any constant multiplier cancels out inside both AdamW's normalized updates and the $y = 0$ vs. $y = 1$ gradient-share ratio.

**Table 1.** Validation Macro-F1 on MS-COCO 2017 across the $\alpha \times T$ grid. Changing only $T$ from 1.0 to 4.0 hurts Macro-F1 by 1.09% to 1.20% at every teacher weight.

$$
{\small
\begin{array}{lccc}
\hline
\boldsymbol{\alpha}\ \textbf{(Teacher Weight)} & \textbf{T = 1.0 Macro-F1} & \textbf{T = 4.0 Macro-F1} & \textbf{Delta (T=4 vs T=1)} \\
\hline
\textbf{Teacher (SO400M-384)} & 81.72\% & \text{—} & \text{Ceiling (87.01\% mAP)} \\
0.0\ \text{(Pure GT baseline)} & 78.84\% & 78.84\% & \text{—} \\
0.5\ \text{(50\% teacher / 50\% GT)} & 79.22\% & 78.08\% & \mathbf{-1.14\%} \\
0.9\ \text{(90\% teacher / 10\% GT)} & 78.73\% & 77.64\% & \mathbf{-1.09\%} \\
1.0\ \text{(100\% teacher / 0\% GT)} & 78.70\% & 77.50\% & \mathbf{-1.20\%} \\
\hline
\end{array}
}
$$

<figure style="text-align: center;">
  <img src="/assets/2026-11-20-Why_T_Greater_than_1_Breaks_Sigmoid_Distillation/wandb_alpha_t_macro_f1.png" alt="MS-COCO Validation Macro-F1 Across alpha x T" style="max-width: 100%; height: auto;">
  <figcaption><strong>Fig. 4.</strong> Validation Macro-F1 across the $\alpha \times T$ grid on MS-COCO 2017 (against the pure GT baseline at 78.84% and the SO400M teacher ceiling at 81.72%). At every teacher weight ($\alpha = 0.5, 0.9, 1.0$), $T = 4.0$ trails $T = 1.0$ by ~1.1%.</figcaption>
</figure>

## Falsifying My First Explanation (7-Temperature Sweep)

Looking at **Table 1** and **Fig. 4**, my first explanation (**Hypothesis A**) felt obvious: because raising $T$ flattens Sigmoid and pushes ~77 absent classes up toward 0.5, the student must be learning inflated absent-class probabilities and spraying **false positives**. If Hypothesis A were true, two things had to show up in validation: **Precision** had to crash, and the average predicted probability on absent classes, $E[p \mid y = 0]$, had to rise.

Macro-F1 merges Precision and Recall into one number, so it cannot tell you whether a drop came from false alarms or missed objects. To test Hypothesis A directly, I split Macro-F1 into Validation Macro-Precision and Macro-Recall at $\alpha = 1.0$ (**Fig. 5**).

<figure style="text-align: center;">
  <img src="/assets/2026-11-20-Why_T_Greater_than_1_Breaks_Sigmoid_Distillation/wandb_precision_vs_recall.png" alt="Validation Macro-Precision vs. Macro-Recall Across Epochs 1-10" style="max-width: 100%; height: auto;">
  <figcaption><strong>Fig. 5.</strong> Validation Macro-Precision and Macro-Recall across Epochs 1–10 at $\alpha = 1.0$ ($T = 1.0$ vs. $T = 4.0$ and $T = 6.0$). Precision stays flat alongside $T = 1.0$ (~88%), falsifying the false-positive hypothesis, while Recall splits below $T = 1.0$ (-1.74 pts at $T = 4.0$ and -2.29 pts at $T = 6.0$; the SO400M teacher sits at 76.90% Macro-R, off-scale above).</figcaption>
</figure>

The data did the exact opposite of what Hypothesis A predicted. Precision stayed flat around ~88% across $T = 1.0$ to $6.0$ (and $E[p \mid y = 0]$ actually *fell* from 0.93% at $T = 1.0$ down to 0.69% at $T = 4.0$ and 0.67% at $T = 6.0$). Instead, **Macro-Recall** dropped cleanly (72.28% down to 70.54% at $T = 4.0$ and 69.99% at $T = 6.0$), alongside $E[p \mid y = 1]$ (73.57% down to 72.15%). The student was not crying wolf; it was missing real objects that were actually in the image.

To see why the model stopped detecting present classes, I logged the share of training gradients coming from absent classes ($y = 0$) versus present classes ($y = 1$). That showed the real mechanism (**Hypothesis B: Negative-Tail Gradient Hijacking**): in BCE, each class's gradient scales with $(p - q)$, so pushing ~77 absent targets up toward 0.27–0.34 gives every absent class a much larger gradient pull. At $T = 4.0$, absent classes hijack **90.30%** of the gradient budget (and **92.54%** at $T = 6.0$), starving the ~3 present classes down to just 9.70% (7.46% at $T = 6.0$). Because the optimizer spends over 90% of its updates fitting absent-class logits, present-class logits are under-trained and Recall drops.

Since two temperatures ($T = 1.0$ vs. $4.0$) cannot show a real trend or find where the sweet spot sits, I ran a full 7-temperature sweep from $T = 0.5$ to $6.0$ at $\alpha = 1.0$ (**Table 2**, **Fig. 6**). The sweep shows two opposite failure modes around $T = 1.0$:
- **Too cold ($T = 0.5$):** Teacher targets sharpen too hard toward 0 and 1, causing absent-class probability leakage $E[p \mid y = 0]$ to double (0.93% to 1.77%) and Val BCE to jump from 0.0376 to 0.0411.
- **Sweet spot ($T = 1.0$):** Sits right at the minimum Val BCE (0.0376) and highest $E[p \mid y = 1]$ (73.57%), keeping present classes at 30.33% of the gradient budget with clean calibration (0.93% absent probability).
- **Too hot ($T = 1.5$ to $6.0$):** Absent-class gradient share climbs steadily from 74.93% to 92.54%, starving present classes (25.07% down to 7.46%) and dragging down Val BCE (0.0384 to 0.0414), Macro-Recall (71.69% to 69.99%), and Macro-F1 (78.16% to 76.99%).

**Table 2.** Full 7-temperature sweep ($T = 0.5$ to $6.0$) at $\alpha = 1.0$ on MS-COCO 2017, alongside the frozen `SO400M-384` teacher. Raising $T > 1.0$ shifts up to 92.54% of the gradient budget onto absent classes ($y = 0$), steadily hurting Recall and $E[p \mid y = 1]$.

$$
{\footnotesize
\begin{array}{lccccccccc}
\hline
\textbf{Run (}\boldsymbol{\alpha}\textbf{=1.0)} & \textbf{y=0 Grad} & \textbf{y=1 Grad} & \textbf{Val BCE} & \textbf{Val mAP} & \textbf{Macro-P} & \textbf{Macro-R} & \textbf{Macro-F1} & \mathbf{E[p \mid y=1]} & \mathbf{E[p \mid y=0]} \\
\hline
\textbf{so400m\_teacher} & 54.69\% & 45.31\% & 0.0363 & 87.01\% & 87.95\% & 76.90\% & 81.72\% & 77.73\% & 0.73\% \\
T = 0.5 & 65.53\% & 34.47\% & 0.0411 & 84.77\% & 88.09\% & \mathbf{72.47\%} & \mathbf{78.72\%} & 72.83\% & \mathbf{1.77\%} \\
T = 1.0 & \mathbf{69.67\%} & \mathbf{30.33\%} & \mathbf{0.0376} & 85.02\% & 88.77\% & 72.28\% & 78.70\% & \mathbf{73.57\%} & 0.93\% \\
T = 1.5 & 74.93\% & 25.07\% & 0.0384 & \mathbf{85.22\%} & 88.86\% & 71.69\% & 78.16\% & 73.50\% & 0.80\% \\
T = 2.0 & 81.11\% & 18.89\% & 0.0392 & 85.06\% & \mathbf{89.14\%} & 71.78\% & 78.46\% & 73.21\% & 0.75\% \\
T = 3.0 & 87.28\% & 12.72\% & 0.0402 & 84.81\% & 88.03\% & 70.96\% & 77.67\% & 72.77\% & 0.70\% \\
T = 4.0 & 90.30\% & 9.70\% & 0.0408 & 84.43\% & 88.34\% & 70.54\% & 77.50\% & 72.50\% & 0.69\% \\
T = 6.0 & \mathbf{92.54\%} & \mathbf{7.46\%} & 0.0414 & 83.98\% & 87.99\% & \mathbf{69.99\%} & \mathbf{76.99\%} & \mathbf{72.15\%} & 0.67\% \\
\hline
\end{array}
}
$$

<figure style="text-align: center;">
  <img src="/assets/2026-11-20-Why_T_Greater_than_1_Breaks_Sigmoid_Distillation/wandb_temp_sweep_two_regimes.png" alt="7-Temperature Sweep: Gradient Share and Failure Regimes" style="max-width: 100%; height: auto;">
  <figcaption><strong>Fig. 6.</strong> 7-temperature sweep ($T = 0.5$ to $6.0$ at $\alpha = 1.0$). Left: absent-class gradient share climbs steadily from 65.5% to 92.5%, starving present classes (34.5% down to 7.5%). Right: $T = 1.0$ sits at the minimum Val BCE (0.0376) between too-cold probability leakage ($T = 0.5$) and too-hot Recall loss ($T > 1$).</figcaption>
</figure>

## Practical Takeaways & Related Work

- **Default to $T = 1.0$ for sparse multi-label Sigmoid distillation.** Do not copy Hinton's $T = 4.0$ Softmax default blindly: $T > 1$ inflates absent-class targets and hands over 90% of the gradient budget to negative labels, while $T < 1$ sharpens targets too hard and causes absent-class probability leakage. When ground-truth labels are also available, mixing them at $T = 1.0$ ($\alpha = 0.5$, 79.22% Macro-F1) beat both pure ground truth (78.84%) and pure teacher distillation (78.70%).
- **Why the student stays ~2.5–3% below the teacher.** Even at the $T = 1.0$ sweet spot, the frozen `SigLIP2-Base-256` student trails `SigLIP2-SO400M-384` (78.70%–79.22% vs. 81.72% Macro-F1). That gap comes from a smaller backbone running at lower input resolution (256px vs. 384px, where small objects lose detail). Keeping both backbones frozen was intentional so we could isolate the distillation loss and temperature behavior without mixing in backbone fine-tuning.
- **Scope limits and related work.** These runs cover one sparse multi-label vision benchmark (MS-COCO 2017, ~96.4% negative sparsity) with frozen backbones. On much denser multi-label tasks (or cross-modal audio settings like AudioSet, where [CMKD (2022)](https://arxiv.org/html/2203.06760v1) reported gains from $T > 1$), the positive-to-negative gradient balance will look different, whereas on datasets with even more classes (hundreds or thousands) negative-tail gradient hijacking should hit even harder. Earlier papers like [Multi-Label Knowledge Distillation (Yang et al., ICCV 2023)](https://openaccess.thecvf.com/content/ICCV2023/papers/Yang_Multi-Label_Knowledge_Distillation_ICCV_2023_paper.pdf), [Multi-label Self Knowledge Distillation (Wang & Wang, AAAI)](https://ojs.aaai.org/index.php/AAAI/article/view/35433/37588), and [Dual-Head Knowledge Distillation (2024)](https://arxiv.org/html/2411.08937v1) also ran into the same issue with standard Softmax KD on multi-label Sigmoid outputs and propose decoupled or binary-KL fixes.

## Appendix

<details>
<summary>Wandb logs</summary>
<iframe
  src="https://forge.coreweave.com/wandb/akash5100-trainbench/siglip2-distill-coco/reports/Why-T-1-Breaks-Sigmoid-Distillation--VmlldzoxODM2MjUyOA?accessToken=s5ab1vpq61ov4buzfkzkqu5s46dvi7pzqj76wun868zwg8ul0ffpwfh18kbs9wm0"
  style="border:none;height:600px;width:100%">
</iframe>
</details>

## Citation

Please cite this work as:

> Verma, Akash. "Why T > 1 Breaks Sigmoid Distillation". *Akash's Blog* (Nov 2026).

```bibtex
@article{verma2026whytgt1breakssigmoiddistillation,
  title   = {Why T > 1 Breaks Sigmoid Distillation},
  author  = {Verma, Akash},
  journal = {akash5100.github.io},
  year    = {2026},
  month   = {November},
  url     = {https://akash5100.github.io/posts/2026-11-20-why_t_greater_than_1_breaks_sigmoid_distillation/}
}
```

## References

1. Zhai, X., Wang, X., Mustafa, B., Steiner, A., Keysers, D., Kolesnikov, A., & Beyer, L. (2022). *LiT: Zero-Shot Transfer with Locked-image text Tuning*. [arXiv:2111.07991](https://arxiv.org/abs/2111.07991)
2. Tschannen, M., et al. (2025). *SigLIP 2: Multilingual Vision-Language Encoders with Improved Semantic Understanding, Localization, and Dense Features*. [arXiv:2502.14786](https://arxiv.org/abs/2502.14786)
3. Hinton, G., Vinyals, O., & Dean, J. (2015). *Distilling the Knowledge in a Neural Network*. [arXiv:1503.02531](https://arxiv.org/abs/1503.02531)
4. Lin, T.-Y., Maire, M., Belongie, S., Bourdev, L., Girshick, R., Hays, J., Perona, P., Ramanan, D., Zitnick, C. L., & Dollár, P. (2014). *Microsoft COCO: Common Objects in Context*. [arXiv:1405.0312](https://arxiv.org/abs/1405.0312)
5. Verma, A. (2026). *trainbench (`experiments/sigmoid_distill`)*. [github.com/akash5100/trainbench/tree/main/experiments/sigmoid_distill](https://github.com/akash5100/trainbench/tree/main/experiments/sigmoid_distill)
6. Wang, X., & Wang, P. *Multi-label Self Knowledge Distillation*. [AAAI](https://ojs.aaai.org/index.php/AAAI/article/view/35433/37588)
7. *Dual-Head Knowledge Distillation: Enhancing Logits Utilization with BinaryKL*. (2024). [arXiv:2411.08937](https://arxiv.org/html/2411.08937v1)
8. Yang, P., Xie, M.-K., Zong, C.-C., Feng, L., Niu, G., Sugiyama, M., & Huang, S.-J. (2023). *Multi-Label Knowledge Distillation*. [ICCV 2023](https://openaccess.thecvf.com/content/ICCV2023/papers/Yang_Multi-Label_Knowledge_Distillation_ICCV_2023_paper.pdf)
9. Gong, Y., Khurana, S., Rouditchenko, A., & Glass, J. (2022). *CMKD: CNN/Transformer-Based Cross-Model Knowledge Distillation for Audio Classification*. [arXiv:2203.06760](https://arxiv.org/html/2203.06760v1)
