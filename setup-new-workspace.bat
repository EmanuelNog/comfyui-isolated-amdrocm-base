@echo off
setlocal enabledelayedexpansion

echo === ComfyUI Isolated Workspace Setup ===
echo.

if "%~1"=="" (
    echo Usage: %~nx0 ^<gpu_arch^> [^<remote_name^> ^<remote_url^>]
    echo e.g.:  %~nx0 gfx120X
    echo         %~nx0 gfx120X my-repo https://github.com/user/repo.git
    echo GPU architectures:
    echo   gfx120X - RX 9070/9060 series
    echo   gfx110X - RX 7XXX series
    echo   gfx1151 - Ryzen AI Max/Strix Halo
    echo   gfx103X - RX 6XXX series
    exit /b 1
)

set gpu_arch=%~1
if not "%~3"=="" (
    set remote_name=%~2
    set remote_url=%~3
) else (
    set remote_name=
    set remote_url=
)

echo.
echo Creating custom_nodes directory...
if not exist custom_nodes mkdir custom_nodes

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
.venv\Scripts\python.exe -c "import torch; print('torch:', torch.__version__); ok = torch.cuda.is_available(); print('ROCm OK - GPU:', torch.cuda.get_device_name(0) if ok else 'NONE'); exit(0 if ok else 1)"
if errorlevel 1 echo WARNING: torch.cuda.is_available() returned False - check GPU architecture selection

echo.
echo Removing origin to protect base repo...
git remote remove origin 2>nul 1>&2
if not "%remote_name%"=="" (
    echo Adding remote "%remote_name%" -> "%remote_url%"...
    git remote remove "%remote_name%" 2>nul 1>&2
    git remote add "%remote_name%" "%remote_url%"
)
echo Setting upstream to fetch-only...
git remote set-url --push upstream no_push 2>nul
git config merge.ours.driver true

echo.
echo Done. Remotes:
git remote -v

echo.
echo Commit and push to your remote must be done manually.
echo.
echo Run with: run.bat
