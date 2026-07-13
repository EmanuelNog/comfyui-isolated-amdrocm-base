#!/usr/bin/env bash
set -euo pipefail
trap 'exit 1' INT

echo "=== ComfyUI Isolated Workspace Setup ==="
echo ""

if [ $# -lt 3 ]; then
    echo "Usage: $(basename "$0") <remote_name> <remote_url> <gpu_arch>"
    echo "e.g.:  $(basename "$0") my-repo https://github.com/user/repo.git gfx120X"
    echo "GPU architectures:"
    echo "  gfx120X - RX 9070/9060 series"
    echo "  gfx110X - RX 7XXX series"
    echo "  gfx1151 - Ryzen AI Max/Strix Halo"
    echo "  gfx103X - RX 6XXX series"
    exit 1
fi

remote_name="$1"
remote_url="$2"
gpu_arch="$3"

echo ""
echo "Creating custom_nodes directory..."
mkdir -p custom_nodes

echo ""
echo "Setting up git remotes..."
git remote remove origin 2>/dev/null || true
git remote add "$remote_name" "$remote_url"
git remote set-url --push upstream no_push
git config merge.ours.driver true

if [ -f .venv/bin/python ]; then
    echo "Virtual environment already exists. Skipping."
else
    echo ""
    echo "Creating venv..."
    uv venv
fi

echo ""
echo "GPU architecture: $gpu_arch"

if .venv/bin/python -c "import torch; assert 'rocm' in torch.__version__, 'no rocm'" 2>/dev/null; then
    echo "ROCm torch already installed. Skipping."
else
    echo "Installing ROCm torch packages..."
    uv pip install --index-url "https://rocm.nightlies.amd.com/v2/${gpu_arch}-all/" --index-strategy unsafe-first-match torch torchaudio torchvision
    uv pip install torchsde
fi

if .venv/bin/python -c "import comfy" 2>/dev/null; then
    echo "ComfyUI dependencies already installed. Skipping."
else
    echo ""
    echo "Installing remaining dependencies..."
    grep -v "^torch" requirements.txt > requirements_no_torch.txt
    uv pip install -r requirements_no_torch.txt
    rm requirements_no_torch.txt
fi

echo ""
echo "Verifying ROCm torch is working..."
.venv/bin/python -c "import torch; print('torch:', torch.__version__); ok = torch.cuda.is_available(); print('ROCm OK - GPU:', torch.cuda.get_device_name(0) if ok else 'NONE'); exit(0 if ok else 1)" || echo "WARNING: torch.cuda.is_available() returned False - check GPU architecture selection"

echo ""
echo "Done. Remotes:"
git remote -v

echo ""
echo "Run with: ./run.sh"
