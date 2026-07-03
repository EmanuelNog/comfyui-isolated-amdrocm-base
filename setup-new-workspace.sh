#!/usr/bin/env bash
set -euo pipefail

echo "=== ComfyUI Isolated Workspace Setup ==="
echo ""

git remote remove origin 2>/dev/null || true

read -p "New remote name: " remote_name
read -p "New remote URL:  " remote_url

git remote add "$remote_name" "$remote_url"

echo ""
echo "Creating venv..."
uv venv

echo "Installing dependencies..."
uv pip install -r requirements.txt

echo ""
echo "Replacing torch packages with ROCm version..."
echo "Choose your GPU architecture:"
echo "  gfx120X - RX 9070/9060 series"
echo "  gfx110X - RX 7XXX series"
echo "  gfx1151 - Ryzen AI Max/Strix Halo"
echo "  gfx103X - RX 6XXX series"
read -p "GPU architecture (e.g. gfx120X): " gpu_arch

uv pip uninstall torch torchvision torchaudio -y
uv pip install --index-url "https://rocm.nightlies.amd.com/v2/${gpu_arch}-all/" torch torchaudio torchvision
uv pip install torchsde

echo ""
echo "Done. Remotes:"
git remote -v

echo ""
echo "Run with: ./run.sh"
