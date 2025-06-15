#Requires -RunAsAdministrator
<#
.SYNOPSIS
Full-Stack Developer Environment Setup with Firewall Workarounds
#>

# ====================
# EXECUTION POLICY SETUP
# ====================
Write-Host "Configuring PowerShell permissions..." -ForegroundColor Cyan
try {
    Set-ExecutionPolicy Bypass -Scope Process -Force -ErrorAction Stop
    Write-Host "Temporary execution policy set for this session" -ForegroundColor Green
}
catch {
    Write-Host "Warning: Could not set execution policy" -ForegroundColor Yellow
}

# ====================
# STEP 1: CREATE DIRECTORY STRUCTURE (WITH FIREWALL WORKAROUND)
# ====================
Write-Host "`nSTEP 1: Creating Directory Structure..." -ForegroundColor Green
$devRoot = "C:\Users\"user"\Documents\DevEnvironment"

# Create root directory with explicit permissions
try {
    if (-not (Test-Path $devRoot)) {
        New-Item -ItemType Directory -Path $devRoot -Force -ErrorAction Stop | Out-Null
        Write-Host "Created main directory: $devRoot" -ForegroundColor Green
    }
}
catch {
    Write-Host "Firewall blocked directory creation. Using alternative location..." -ForegroundColor Yellow
    $devRoot = "C:\DevEnvironment"
    New-Item -ItemType Directory -Path $devRoot -Force | Out-Null
}

$folders = @(
    "Projects\Web\Frontend",
    "Projects\Web\Backend",
    "Projects\Mobile",
    "Projects\Templates",
    "Libraries\JavaScript",
    "Libraries\Python",
    "Libraries\DotNet",
    "Tools\CLI",
    "Tools\IDEs",
    "Docs\Cheatsheets",
    "Sandbox\Testing",
    "Docker\Configs"
)

foreach ($folder in $folders) {
    $fullPath = Join-Path -Path $devRoot -ChildPath $folder
    try {
        if (-not (Test-Path $fullPath)) {
            New-Item -ItemType Directory -Path $fullPath -Force -ErrorAction Stop | Out-Null
            Write-Host "Created: $fullPath" -ForegroundColor DarkGray
        }
    }
    catch {
        Write-Host "Skipped (firewall): $fullPath" -ForegroundColor Yellow
    }
}

# ====================
# STEP 2: INSTALL CHOCOLATEY
# ====================
Write-Host "`nSTEP 2: Installing Chocolatey Package Manager..." -ForegroundColor Green
if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    try {
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        Write-Host "Chocolatey installed successfully" -ForegroundColor Cyan
    }
    catch {
        Write-Host "Failed to install Chocolatey" -ForegroundColor Red
        Write-Host "You may need to install packages manually" -ForegroundColor Yellow
    }
}
else {
    Write-Host "Chocolatey already installed" -ForegroundColor DarkYellow
}

# ====================
# STEP 3: INSTALL CORE TOOLS
# ====================
Write-Host "`nSTEP 3: Installing Development Tools..." -ForegroundColor Green
$tools = @(
    "git",             # Version control
    "vscode",          # Code editor
    "nodejs-lts",      # JavaScript runtime
    "python",          # Python interpreter
    "docker-desktop",  # Container platform
    "postman",         # API testing
    "dbeaver",         # Database manager
    "powershell-core"  # Modern PowerShell
)

foreach ($tool in $tools) {
    try {
        choco install $tool -y --no-progress
    }
    catch {
        Write-Host "Failed to install $tool (firewall?)" -ForegroundColor Yellow
        Write-Host "Please install manually from chocolatey.org" -ForegroundColor Cyan
    }
}

# ====================
# STEP 4: INSTALL VS CODE EXTENSIONS
# ====================
Write-Host "`nSTEP 4: Installing VS Code Extensions..." -ForegroundColor Green
$extensions = @(
    "ms-vscode.PowerShell",
    "esbenp.prettier-vscode",
    "dbaeumer.vscode-eslint",
    "ms-azuretools.vscode-docker",
    "ms-vscode.vscode-typescript-next",
    "eamodio.gitlens"
)

foreach ($ext in $extensions) {
    try {
        code --install-extension $ext --force 2>&1 | Out-Null
    }
    catch {
        Write-Host "Failed to install $ext" -ForegroundColor Yellow
    }
}

# ====================
# STEP 5: CONFIGURE GIT
# ====================
Write-Host "`nSTEP 5: Configuring Git..." -ForegroundColor Green
git config --global user.name "user"
git config --global user.email "user@email.com"
git config --global core.autocrlf true
git config --global init.defaultBranch main
git config --global pull.rebase merges
git config --global alias.st "status -s"
git config --global alias.ci "commit"
git config --global alias.co "checkout"
git config --global alias.br "branch"

Write-Host "Git configured for:" -ForegroundColor Cyan
Write-Host "Name  : "user" -ForegroundColor Yellow
Write-Host "Email : user@mail.com" -ForegroundColor Yellow
Write-Host "Branch: main" -ForegroundColor Yellow

# ====================
# STEP 6: CREATE POWERSHELL SHORTCUTS (FIREWALL SAFE)
# ====================
Write-Host "`nSTEP 6: Creating PowerShell Shortcuts..." -ForegroundColor Green

# Define profile content
$profileContent = @"
# DEVELOPMENT ENVIRONMENT SHORTCUTS

# Navigation
function dev { Set-Location "$devRoot" }
function proj { Set-Location "$devRoot\Projects" }
function libs { Set-Location "$devRoot\Libraries" }
function docs { Set-Location "$devRoot\Docs" }

# Git Aliases
function gs { git status -s }
function ga { git add . }
function gc { git commit -m `$args }
function gac { git add . && git commit -m `$args }
function gp { git push }
function gpl { git pull }

# Docker Commands
function dcup { docker-compose up -d }
function dcdown { docker-compose down }
function dcls { docker container ls -a }

# Utilities
function exp { explorer . }
function code. { code . }

# Environment Variables
`$env:DEV_ROOT = "$devRoot"
"@

# Try to create profile in Documents
$docProfilePath = "$env:USERPROFILE\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"
try {
    $profileDir = [System.IO.Path]::GetDirectoryName($docProfilePath)
    if (-not (Test-Path $profileDir)) {
        New-Item -ItemType Directory -Path $profileDir -Force -ErrorAction Stop | Out-Null
    }
    $profileContent | Out-File $docProfilePath -Encoding utf8 -Force
    Write-Host "Profile created in Documents" -ForegroundColor Cyan
}
catch {
    Write-Host "Firewall blocked Documents location. Using alternative..." -ForegroundColor Yellow
    
    # Fallback to DevEnvironment directory
    $altProfilePath = "$devRoot\PowerShell_Profile.ps1"
    $profileContent | Out-File $altProfilePath -Encoding utf8 -Force
    
    # Create loader command
    $loaderCommand = ". '$altProfilePath'"
    
    # Try to add to existing profile
    try {
        if (Test-Path $docProfilePath) {
            Add-Content -Path $docProfilePath -Value "`n$loaderCommand"
        }
        else {
            # Try to create in home directory
            $homeProfile = "$env:USERPROFILE\Microsoft.PowerShell_profile.ps1"
            $loaderCommand | Out-File $homeProfile -Encoding utf8 -Force
        }
    }
    catch {
        Write-Host "Could not create automatic loader" -ForegroundColor Red
        Write-Host "MANUAL STEP REQUIRED: Add this to your PowerShell profile:" -ForegroundColor Yellow
        Write-Host $loaderCommand -ForegroundColor Cyan
    }
    
    Write-Host "Profile created at: $altProfilePath" -ForegroundColor Cyan
}

# ====================
# STEP 7: INSTALL WSL (OPTIONAL)
# ====================
Write-Host "`nSTEP 7: Install WSL?" -ForegroundColor Green
$installWSL = Read-Host "Install Windows Subsystem for Linux with Ubuntu? (y/n)"
if ($installWSL -eq 'y') {
    try {
        wsl --install -d Ubuntu
        Write-Host "WSL installed. REBOOT REQUIRED!" -ForegroundColor Yellow
    }
    catch {
        Write-Host "Failed to install WSL (firewall?)" -ForegroundColor Red
        Write-Host "Install manually: https://learn.microsoft.com/en-us/windows/wsl/install" -ForegroundColor Cyan
    }
}

# ====================
# STEP 8: INSTALL GLOBAL NPM PACKAGES
# ====================
Write-Host "`nSTEP 8: Installing Global NPM Packages..." -ForegroundColor Green
$npmPackages = @(
    "npm",
    "typescript",
    "nodemon",
    "create-react-app",
    "express-generator",
    "firebase-tools"
)

foreach ($pkg in $npmPackages) {
    try {
        npm install -g $pkg
    }
    catch {
        Write-Host "Failed to install $pkg" -ForegroundColor Yellow
    }
}

# ====================
# STEP 9: CREATE STARTER FILES
# ====================
Write-Host "`nSTEP 9: Creating Starter Files..." -ForegroundColor Green

# Create README.md
try {
    @"
# DEVELOPMENT ENVIRONMENT

**Root Location**: $devRoot  
**Created**: $(Get-Date -Format "yyyy-MM-dd HH:mm")  

## QUICK COMMAND REFERENCE
| Command | Description                  |
|---------|------------------------------|
| `dev`   | Go to development root       |
| `proj`  | Go to projects folder        |
| `gs`    | Short git status             |
| `gac`   | Add all + commit             |
| `dcup`  | Start Docker containers      |
| `code.` | Open VS Code in current dir  |

## GIT CONFIGURATION
- **Name**: "user"
- **Email**: user@mail.com
- **Default Branch**: main
"@ | Out-File "$devRoot\README.md" -Encoding utf8
}
catch {
    Write-Host "Could not create README.md" -ForegroundColor Yellow
}

# ====================
# COMPLETION
# ====================
Write-Host "`nSETUP COMPLETE!" -ForegroundColor Green -BackgroundColor Black
Write-Host "Development environment ready at: $devRoot" -ForegroundColor Cyan
Write-Host "`nNEXT STEPS:" -ForegroundColor Yellow
Write-Host "1. RESTART YOUR TERMINAL"
Write-Host "2. Run 'dev' to navigate to your environment"
Write-Host "3. Open VS Code and start coding!"
Write-Host "4. Check README.md for reference"

if ($installWSL -eq 'y') {
    Write-Host "`nWARNING: SYSTEM REBOOT REQUIRED FOR WSL!" -ForegroundColor Red
}

Write-Host "`nIf any steps failed due to firewall:" -ForegroundColor Cyan
Write-Host "- Temporarily disable 'Controlled Folder Access'" -ForegroundColor Yellow
Write-Host "- Re-run this script" -ForegroundColor Cyan