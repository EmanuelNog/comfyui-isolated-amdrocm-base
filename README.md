# ComfyUI AMD ROCm Base

This is a fork of [ComfyUI](https://github.com/comfyanonymous/ComfyUI) configured as an isolated self-contained workspace for **AMD ROCm GPUs** (RX 9070/9060, RX 7XXX, RX 6XXX, Ryzen AI Max).

The repository must remain self-contained — all configuration, setup, and runtime scripts live inside the repo. This keeps commit tracking simple and makes the workspace reproducible from a fresh clone.

## Purpose

Running ComfyUI on AMD GPUs requires replacing standard PyTorch (CUDA) with ROCm-compatible wheels from AMD's nightly index. This repo provides a clean, repeatable setup that installs ROCm torch automatically and avoids pulling in CUDA torch from PyPI — even through transitive dependencies.

## Setup

From a clean clone:

**Windows:**
```
setup-new-workspace.bat <gpu_arch> [<remote_name> <remote_url>]
```

**Linux:**
```
bash setup-new-workspace.sh <gpu_arch> [<remote_name> <remote_url>]
```

The script is **idempotent** — re-running it skips already-completed steps. It will:
1. Create `custom_nodes/` directory
2. Create a Python virtual environment with `uv`
3. Install ROCm torch, torchvision, torchaudio directly from `https://rocm.nightlies.amd.com`
4. Install remaining ComfyUI dependencies (torch lines filtered out)
5. Verify ROCm is working (`torch.cuda.is_available()`)
6. Remove `origin` (protects base repo) and set `upstream` to fetch-only
7. If `remote_name` and `remote_url` are provided, add that remote

GPU architectures:
- `gfx120X` — RX 9070/9060 series
- `gfx110X` — RX 7XXX series
- `gfx1151` — Ryzen AI Max / Strix Halo
- `gfx103X` — RX 6XXX series

## Running

```
run.bat          # Windows
./run.sh         # Linux
```

Or manually:
```
.venv\Scripts\python main.py --use-pytorch-cross-attention --bf16-vae --disable-smart-memory
```

## Keeping upstream changes

```
git pull upstream master
```

The README is configured to always keep this version on merge — upstream's README changes are discarded automatically. Other files merge normally; resolve any conflicts in those manually.
