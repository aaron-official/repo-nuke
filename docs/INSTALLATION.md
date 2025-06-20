# Installation Guide

## Prerequisites
- **GitHub CLI (`gh`)** must be installed and authenticated.
- Python 3.7+ (for Python version)
- Bash (for Unix/Linux/macOS)
- PowerShell (for Windows)

## Installation Steps

### 1. Clone the Repository
```sh
git clone https://github.com/aaron-official/repo-nuke.git
cd repo-nuke
```

### 2. Install GitHub CLI
- **Windows:**
  ```sh
  winget install --id GitHub.cli
  ```
- **macOS:**
  ```sh
  brew install gh
  ```
- **Linux (Debian/Ubuntu):**
  ```sh
  sudo apt install gh
  ```

### 3. Authenticate GitHub CLI
```sh
gh auth login
gh auth refresh -h github.com -s delete_repo
```

### 4. (Optional) Make Scripts Executable (Unix)
```sh
chmod +x batch_delete.sh scripts/install-deps.sh
```

### 5. Install Python Dependencies (if any)
No external dependencies required for the default scripts.

---

You are now ready to use RepoNuke on your platform!
