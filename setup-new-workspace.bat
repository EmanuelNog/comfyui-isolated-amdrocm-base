@echo off
setlocal enabledelayedexpansion

echo === ComfyUI Isolated Workspace Setup ===
echo.

git remote remove origin 2>nul

set /p remote_name="New remote name: "
set /p remote_url="New remote URL:  "

git remote add "%remote_name%" "%remote_url%"

echo.
echo Creating venv...
uv venv

echo Installing dependencies...
uv pip install -r requirements.txt

echo.
echo Replacing torch packages with ROCm version...
echo Choose your GPU architecture:
echo   gfx120X - RX 9070/9060 series
echo   gfx110X - RX 7XXX series
echo   gfx1151 - Ryzen AI Max/Strix Halo
echo   gfx103X - RX 6XXX series
set /p gpu_arch="GPU architecture (e.g. gfx120X): "

uv pip uninstall torch torchvision torchaudio -y
uv pip install --index-url https://rocm.nightlies.amd.com/v2/%gpu_arch%-all/ torch torchaudio torchvision
uv pip install torchsde

echo.
echo Done. Remotes:
git remote -v

echo.
echo Run with: run.bat
