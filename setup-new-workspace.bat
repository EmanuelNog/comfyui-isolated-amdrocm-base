@echo off
setlocal enabledelayedexpansion

echo === ComfyUI Isolated Workspace Setup ===
echo.

if "%~3"=="" (
    echo Usage: %~nx0 ^<remote_name^> ^<remote_url^> ^<gpu_arch^>
    echo e.g.:  %~nx0 my-repo https://github.com/user/repo.git gfx120X
    echo GPU architectures:
    echo   gfx120X - RX 9070/9060 series
    echo   gfx110X - RX 7XXX series
    echo   gfx1151 - Ryzen AI Max/Strix Halo
    echo   gfx103X - RX 6XXX series
    exit /b 1
)

set remote_name=%~1
set remote_url=%~2
set gpu_arch=%~3

echo.
echo Creating custom_nodes directory...
if not exist custom_nodes mkdir custom_nodes

echo.
echo Setting up git remotes...
git remote remove origin 2>nul 1>&2
git remote add "%remote_name%" "%remote_url%"
git remote set-url --push upstream no_push
git config merge.ours.driver true

if exist .venv\Scripts\python.exe (
    echo Virtual environment already exists. Skipping.
) else (
    echo.
    echo Creating venv...
    uv venv || exit /b
)

echo.
echo GPU architecture: %gpu_arch%

.venv\Scripts\python.exe -c "import torch; assert 'rocm' in torch.__version__, 'no rocm'" 2>nul
if errorlevel 1 (
    echo Installing ROCm torch packages...
    uv pip install --index-url https://rocm.nightlies.amd.com/v2/%gpu_arch%-all/ --index-strategy unsafe-first-match torch torchaudio torchvision || exit /b
    uv pip install torchsde || exit /b
) else (
    echo ROCm torch already installed. Skipping.
)

.venv\Scripts\python.exe -c "import comfy" 2>nul
if errorlevel 1 (
    echo.
    echo Installing remaining dependencies...
    findstr /v /b "torch" requirements.txt > requirements_no_torch.txt
    uv pip install -r requirements_no_torch.txt || exit /b
    del requirements_no_torch.txt
) else (
    echo ComfyUI dependencies already installed. Skipping.
)

echo.
echo Verifying ROCm torch is working...
.venv\Scripts\python -c "import torch; print('torch:', torch.__version__); ok = torch.cuda.is_available(); print('ROCm OK - GPU:', torch.cuda.get_device_name(0) if ok else 'NONE'); exit(0 if ok else 1)"
if errorlevel 1 echo WARNING: torch.cuda.is_available() returned False - check GPU architecture selection

echo.
echo Done. Remotes:
git remote -v

echo.
echo Run with: run.bat
