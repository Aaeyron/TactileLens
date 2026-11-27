# Online model

These tools test the model used for **online scanning** (PaddleOCR-VL)
and prepare data in case we train our own copy of it later.

**We have not trained this model.** It is used as it comes.

- PaddleOCR's hosted service (by Baidu) **cannot be trained** by us.
- Only our own copy of the open model could be trained, and that needs a
  much bigger graphics card than ours, plus our own server to run it.
  This is future work.

## The usual steps

1. **Convert labeled photos** (`convert_to_sft.py`) into the format the
   model's training tool (ERNIEKit) expects. If anything is wrong, or a
   test photo would end up in training, nothing is written.
2. **Test the model** (`evaluate_vl.py`) on the photos kept aside for
   testing, either on this PC or through Baidu's service. Only send photos
   you are allowed to share, because Baidu keeps them.

## Photo names and labels

Photos are named `topic_source_kind_number`, for example
`radicals_ss_S_001.png`:

- **source:** `ss` = screenshot, `cap` = phone photo
- **kind:** `S` = one formula, `M` = several formulas, `T` = text with
  math, `W` = a whole worksheet page

The labels file has one row per photo: `filename,task,target,split`.

## Other tools

| Tool | What it's for |
|---|---|
| `suggest_vl_resumable.py` | let the model read many photos to suggest labels; picks up where it left off after a crash |
| `local_vl_worker.py` | runs the model on this PC for the other tools |
| `make_fake_dataset.py` | make a small fake set of photos to test these tools |
| `colab_sft.ipynb`, `colab_lora_sft.ipynb` | prepared training notebooks for Google Colab (**never run**) |

Each tool explains its options with `--help`, and the folder has its own
automatic tests. More details:
[docs/training_runbook.md](../../docs/training_runbook.md) and
[docs/vl_finetuning_feasibility.md](../../docs/vl_finetuning_feasibility.md).
