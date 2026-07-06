#!/usr/bin/env bash
set -euo pipefail
trap 'exit 1' INT

echo "=== ComfyUI Isolated Workspace Setup ==="
echo ""

git remote remove origin 2>/dev/null || true

read -p "New remote name: " remote_name
read -p "New remote URL:  " remote_url

git remote add "$remote_name" "$remote_url"
git remote set-url --push upstream no_push

echo ""
echo "Creating venv..."
uv venv

echo ""
echo "Choose your GPU architecture:"
echo "  gfx120X - RX 9070/9060 series"
echo "  gfx110X - RX 7XXX series"
echo "  gfx1151 - Ryzen AI Max/Strix Halo"
echo "  gfx103X - RX 6XXX series"
read -p "GPU architecture (e.g. gfx120X): " gpu_arch

echo ""
echo "Installing ROCm torch packages first..."
uv pip install --index-url "https://rocm.nightlies.amd.com/v2/${gpu_arch}-all/" --index-strategy unsafe-first-match torch torchaudio torchvision
uv pip install torchsde

echo ""
echo "Installing remaining dependencies..."
grep -v "^torch" requirements.txt > requirements_no_torch.txt
uv pip install -r requirements_no_torch.txt
rm requirements_no_torch.txt

echo ""
echo "Verifying ROCm torch is working..."
.venv/bin/python -c "import torch; print('torch:', torch.__version__); assert torch.cuda.is_available(), 'ROCm NOT working!'; print('ROCm OK - GPU:', torch.cuda.get_device_name(0))" || echo "WARNING: torch.cuda.is_available() returned False - check GPU architecture selection"

echo ""
echo "Done. Remotes:"
git remote -v

echo ""
echo "Run with: ./run.sh"
