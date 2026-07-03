@echo off
set FLASH_ATTENTION_TRITON_AMD_ENABLE=TRUE
set TORCH_ROCM_AOTRITON_ENABLE_EXPERIMENTAL=1
uv run python main.py --use-pytorch-cross-attention --bf16-vae --disable-smart-memory %*
pause
