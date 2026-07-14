# Claude Brain Setup - One-line web installer (Windows PowerShell)
#
# Downloads the repository archive to a temporary folder, extracts it and
# starts the interactive setup wizard from there. No git required.
#
# One-liner (paste into PowerShell):
#   irm https://raw.githubusercontent.com/JanniEinfach/claude-brain-setup/main/scripts/bootstrap.ps1 | iex
#
# Notes:
#   - No admin rights required. Nothing outside your user profile is touched.
#   - Network access: one download from codeload.github.com (the repo archive).
#   - Cleanup removes ONLY the temporary extraction folder created by this
#     script. It never deletes any of your files.
#
# The whole script lives inside a single function so that running it via
# `irm | iex` cannot leak variables or preferences into your shell session.

function Invoke-ClaudeBrainBootstrap {
    $Repo    = 'JanniEinfach/claude-brain-setup'
    $Branch  = 'main'
    $ZipUrl  = "https://codeload.github.com/$Repo/zip/refs/heads/$Branch"

    # Function-scoped: reverts automatically when the function returns.
    $ErrorActionPreference = 'Stop'

    Write-Host ""
    Write-Host "Claude Brain Setup - Bootstrap (Windows)" -ForegroundColor Cyan
    Write-Host "=========================================" -ForegroundColor Cyan
    Write-Host ""

    # GitHub requires TLS 1.2; Windows PowerShell 5.1 may not enable it by default.
    try {
        [Net.ServicePointManager]::SecurityProtocol = `
            [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
    } catch {
        Write-Warning "Could not enable TLS 1.2 - the download may fail on older systems."
    }

    $Stamp   = Get-Date -Format 'yyyyMMdd_HHmmss'
    $WorkDir = Join-Path $env:TEMP "claude-brain-bootstrap_$Stamp"

    try {
        New-Item -ItemType Directory -Path $WorkDir -Force | Out-Null

        # 1. Download the repository archive.
        $ZipPath = Join-Path $WorkDir 'claude-brain-setup.zip'
        Write-Host "Downloading: $ZipUrl"
        Invoke-WebRequest -Uri $ZipUrl -OutFile $ZipPath -UseBasicParsing
        Write-Host "Download complete." -ForegroundColor Green

        # 2. Extract it.
        $ExtractDir = Join-Path $WorkDir 'extract'
        Write-Host "Extracting archive..."
        Expand-Archive -Path $ZipPath -DestinationPath $ExtractDir

        # 3. Locate the setup wizard inside the extracted archive.
        $SetupScript = Get-ChildItem -Path $ExtractDir -Recurse -Filter 'setup.ps1' |
            Where-Object { $_.Directory.Name -eq 'scripts' } |
            Select-Object -First 1
        if ($null -eq $SetupScript) {
            throw "setup.ps1 not found in the downloaded archive. The download may be incomplete - please try again."
        }

        # 4. Run the interactive wizard as a child process so it inherits this
        #    console and can ask questions, regardless of execution policy.
        Write-Host ""
        Write-Host "Starting the interactive setup wizard..." -ForegroundColor Cyan
        Write-Host ""
        & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $SetupScript.FullName
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "The setup wizard exited with code $LASTEXITCODE."
            Write-Host "You can run it again any time:"
            Write-Host "  git clone https://github.com/$Repo.git"
            Write-Host "  cd claude-brain-setup"
            Write-Host "  .\scripts\setup.ps1"
        }
    } finally {
        # Remove ONLY the temporary folder this script created.
        if (Test-Path $WorkDir) {
            Remove-Item -Path $WorkDir -Recurse -Force -Confirm:$false -ErrorAction SilentlyContinue
        }
    }
}

Invoke-ClaudeBrainBootstrap
