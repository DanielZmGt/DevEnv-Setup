# Full-Stack Developer Environment Setup Script

Automates setup of a complete development environment on Windows with:
- Directory structure organization
- Essential tool installations
- PowerShell shortcut configuration
- Git setup

## Features
- Creates organized project structure
- Installs VS Code, Git, Node.js, Docker
- Configures PowerShell with productivity aliases
- Sets up development shortcuts (`dev`, `proj`, `gs` etc.)

## Usage
```powershell
# Run in PowerShell as Administrator
Set-ExecutionPolicy Bypass -Scope Process -Force
.\Setup-DevEnv.ps1
```

## Customization
Edit these sections in the script:
1. **Git Configuration** (Line 100+)
2. **Directory Structure** (Line 25+)
3. **Tools List** (Line 60+)

"This script was developed with AI assistance."
