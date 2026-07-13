@echo off
setlocal enabledelayedexpansion

echo === ComfyUI Isolated Workspace Setup ===
echo.

if "%~1"=="" (
    echo Usage: %~nx0 ^<remote_name^> ^<remote_url^>
    echo e.g.:  %~nx0 my-repo https://github.com/user/repo.git
    exit /b 1
)
if "%~2"=="" (
    echo Usage: %~nx0 ^<remote_name^> ^<remote_url^>
    exit /b 1
)

set remote_name=%~1
set remote_url=%~2

git remote remove origin 2>nul

git remote add "%remote_name%" "%remote_url%"
git remote set-url --push upstream no_push
git config merge.ours.driver true

echo.
echo Creating custom_nodes directory...
if not exist custom_nodes mkdir custom_nodes

echo.
echo Creating venv...
uv venv || exit /b

echo.
echo Choose your GPU architecture (default: gfx120X):
echo   gfx120X - RX 9070/9060 series
echo   gfx110X - RX 7XXX series
echo   gfx1151 - Ryzen AI Max/Strix Halo
echo   gfx103X - RX 6XXX series
set gpu_arch=gfx120X
set /p gpu_arch="GPU architecture (press Enter for default gfx120X): "

echo.
echo Installing ROCm torch packages first...
uv pip install --index-url https://rocm.nightlies.amd.com/v2/%gpu_arch%-all/ --index-strategy unsafe-first-match torch torchaudio torchvision || exit /b
uv pip install torchsde || exit /b

echo.
echo Installing remaining dependencies...
findstr /v /b "torch" requirements.txt > requirements_no_torch.txt
uv pip install -r requirements_no_torch.txt || exit /b
del requirements_no_torch.txt

echo.
echo Verifying ROCm torch is working...
.venv\Scripts\python -c "import torch; print('torch:', torch.__version__); ok = torch.cuda.is_available(); print('ROCm OK - GPU:', torch.cuda.get_device_name(0) if ok else 'NONE'); exit(0 if ok else 1)"
if errorlevel 1 echo WARNING: torch.cuda.is_available() returned False - check GPU architecture selection

echo.
echo Done. Remotes:
git remote -v

echo.
echo Run with: run.bat
