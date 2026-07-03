#!/usr/bin/env bash
export FLASH_ATTENTION_TRITON_AMD_ENABLE=TRUE
export TORCH_ROCM_AOTRITON_ENABLE_EXPERIMENTAL=1
uv run python main.py --use-pytorch-cross-attention --bf16-vae --disable-smart-memory "$@"
