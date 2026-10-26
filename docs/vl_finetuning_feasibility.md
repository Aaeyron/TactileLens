# PaddleOCR-VL fine-tuning: feasibility

Status (2026-10-26): **estimate only. Nothing has been trained or measured
for training**; every memory and time figure below is calculated, not
observed. Tools: `tools/training_vl/` (converter, evaluation harness,
Colab notebook `colab_sft.ipynb`, never run).

## What can be fine-tuned

- **Baidu's hosted API (the app's online engine) cannot be fine-tuned.**
  Nothing here trains through it.
- ERNIEKit documents full fine-tuning (SFT) of **`PaddlePaddle/PaddleOCR-VL`
  (0.9B)**: https://ernie.readthedocs.io/en/develop/paddleocr_vl_sft.html
  (`/en/latest/` returns 404). LoRA and freezing the vision encoder are
  not documented for this model.
- The app uses **PaddleOCR-VL-1.6**. Fine-tuning 1.6 with ERNIEKit is
  **not verified** (the guide only names the 0.9B model).
- A fine-tuned model must run on **our own GPU hosting**. The app's hosted
  engine would keep using Baidu's model.

## The model and the example recipe

| | value | source |
|---|---|---|
| download | `PaddlePaddle/PaddleOCR-VL`, about 2.0 GiB (`model.safetensors` 1.79 GiB) | Hugging Face listing |
| parameters | about 0.96 B (1,917,255,968 bytes of bf16 weights in our 1.6 copy, same size as 0.9B) | file size / 2 |
| split (calculated from `config.json`) | vision encoder about 0.41 B, language model about 0.47 B (incl. 2 × 0.11 B embeddings), projector the rest | layer sizes |
| image tokens | one per 28 × 28 px, at most about 1,280 per image (`max_pixels` 1,003,520), at least 144 | `preprocessor_config.json` |
| example config | `run_ocr_vl_sft_16k.yaml`: full fine-tuning, `compute_type: bf16`, `use_flash_attention: True`, recompute full, batch 1, packing 8, grad accumulation 8, `max_seq_len` 16384, lr 5e-6 | ERNIEKit repo |
| stated hardware | "approximately 2 hours on a single A800-80G GPU"; ERNIEKit lists Ampere/Hopper 80 GB, CUDA ≥ 12.3, Python 3.10–3.12 | ERNIEKit docs |

## Memory estimate (full fine-tuning, AdamW, mixed precision)

| part | per parameter | about |
|---|---|---|
| bf16 weights | 2 B | 1.9 GB |
| fp32 master weights | 4 B | 3.8 GB |
| Adam moments (fp32) | 8 B | 7.7 GB |
| bf16 gradients | 2 B | 1.9 GB |
| **fixed state** | **16 B** | **about 15 GB** |
| activations, 16k packed tokens with recompute | | a few GB (vision encoder about 2.5 GB for 8 full-size images) |
| CUDA context, allocator | | about 1 GB |

So about **20 GB in total** with the example settings, less with shorter
packing (`max_seq_len` 4096–8192 is plenty for formula crops of 200–400
image tokens).

## Where it can run

| GPU | verdict | why |
|---|---|---|
| RTX 4050 Laptop 6 GB (ours) | **no** | the fixed state alone is about 15 GB. It does run PaddleOCR-VL-1.6 *inference* (measured: 2.3–4.2 s per small image, model load about 26 s) |
| Colab free T4 16 GB | **no** | 15 GB fixed state leaves nothing for activations; Turing has no bf16 and no FlashAttention-2, both used by the example config. fp16 or no-flash-attention runs are not documented |
| L4 24 GB (Colab paid) | uncertain | bf16 yes; would need short sequences; not documented |
| A100 40 GB (Colab paid) | **likely** | about 20 GB estimated; the notebook targets this and stops on smaller GPUs |
| A100/A800 80 GB | yes | the documented setup |

Time: the guide's run (926 steps, packing 8, accumulation 8) took about
2 h on an A800. A dataset of a few thousand crops would take a fraction
of that; not measured.

## Downloads (none done)

- base model `PaddlePaddle/PaddleOCR-VL`: about 2.0 GiB
- `paddlepaddle-gpu` 3.2 (CUDA 12.6) wheel and the ERNIE repo with its
  requirements: size not checked
- on our PC, an un-tuned 0.9B baseline for comparison would be another
  about 2 GiB (needs approval)

## Plan if approved

1. Label our own images (`topic_source_kind_number`, labels CSV) and run
   `convert_to_sft.py` (leak guard: eval images never in train/val).
2. Evaluate the current engines on the held-out set: local 1.6 (we can),
   hosted (the owner runs it), and later un-tuned 0.9B.
3. Fine-tune on a Colab A100 with `colab_sft.ipynb`, then evaluate with
   `evaluate_vl.py --engine finetuned`. Only a clear win on the held-out
   set would justify hosting our own GPU server.

Any change that affects Braille output goes to the Braille expert first.
