# RepoNuke - Bulk GitHub Repository Deletion Tool

**The ultimate cross-platform tool for bulk deleting GitHub repositories safely and efficiently.**

> 🚀 **Nuclear-powered repository cleanup** - Delete multiple GitHub repos at once with comprehensive safety features, interactive selection, and professional-grade logging.

## ⚠️ Important Safety Warning

**This tool permanently deletes GitHub repositories. This action is irreversible!**
- Always backup important code before using RepoNuke
- Test with non-critical repositories first
- Double-check repository names in the confirmation prompt
- Use dry-run mode to preview operations

## ✨ Why Choose RepoNuke?

**Perfect for developers who need to:**
- Clean up old test repositories and abandoned projects
- Perform bulk repository maintenance across organizations
- Remove multiple forked repositories after pull requests
- Declutter GitHub profiles and organization accounts
- Automate repository lifecycle management
- Bulk delete repositories from CI/CD pipelines or scripts

## 🎯 Key Features

### Safety & Control
- 🛡️ **Multiple confirmation prompts** to prevent accidental deletions
- 👁️ **Dry-run mode** - Preview what will be deleted without making changes
- ✅ **Repository validation** - Verify access and existence before deletion
- 📋 **Interactive selection menu** with numbered repository list
- 🔍 **Username verification** to prevent cross-account accidents

### Platform & Integration
- 🌐 **Cross-platform support** - Windows PowerShell, Bash (macOS/Linux), Python
- ⚡ **GitHub CLI integration** - Uses official GitHub CLI for secure API access
- 🔐 **Automatic authentication** checking and permission validation
- 📊 **Comprehensive logging** with timestamped audit trails
- 🎨 **Colorized terminal output** for enhanced user experience

### Batch Operations
- 📁 **Load repository lists** from text files or JSON configuration
- 🚀 **Concurrent processing** with built-in rate limiting
- 📈 **Progress tracking** with real-time deletion status
- 📊 **Detailed summary reports** showing success/failure statistics
- ⏱️ **Intelligent delays** to respect GitHub API rate limits

## 🚀 Quick Start Guide

### Prerequisites

1. **Install GitHub CLI**
   ```bash
   # Windows
   winget install --id GitHub.cli
   
   # macOS
   brew install gh
   
   # Linux (Ubuntu/Debian)
   sudo apt install gh
   ```

2. **Authenticate with GitHub**
   ```bash
   gh auth login
   gh auth refresh -h github.com -s delete_repo
   ```

### Installation Methods

#### Method 1: Direct Download (Recommended)
```bash
# Clone RepoNuke
git clone https://github.com/aaron-official/repo-nuke.git
cd repo-nuke

# Make executable (Unix/Linux/macOS)
chmod +x batch_delete.sh

# Run interactive mode
./batch_delete.sh --interactive        # Unix/Linux/macOS
./batch_delete.ps1 -Interactive        # Windows PowerShell
python batch_delete.py --interactive   # Cross-platform Python
```

#### Method 2: Direct Usage
```bash
# Delete specific repositories
./batch_delete.sh repo1 repo2 repo3

# PowerShell (Windows)
pwsh ./batch_delete.ps1 -Repositories repo1,repo2,repo3

# Load from file
echo -e "old-project\ntest-repo\ntemporary-fork" > cleanup-list.txt
./batch_delete.sh --file cleanup-list.txt
pwsh ./batch_delete.ps1 -File cleanup-list.txt

# Use JSON configuration
./batch_delete.sh --config repositories.json
pwsh ./batch_delete.ps1 -Config repositories.json
```

## 📖 Usage Examples

### Interactive Mode (Safest for Beginners)
```bash
$ ./batch_delete.sh --interactive

🔧 RepoNuke - GitHub Repository Deletion Tool
============================================
👤 Using GitHub username: aaron-official
📋 Fetching your repositories...

🎯 Interactive Repository Selection
Available repositories:
  1) old-test-project
  2) abandoned-experiment  
  3) temporary-fork
  4) important-project
  5) work-in-progress

Enter repository numbers to delete (space-separated, e.g., 1 3 5):
> 1 2 3

Repositories to be deleted:
  - aaron-official/old-test-project
  - aaron-official/abandoned-experiment
  - aaron-official/temporary-fork

⚠️  WARNING: This action is IRREVERSIBLE!
Are you absolutely sure? Type 'DELETE' to confirm: DELETE

✅ Successfully deleted: aaron-official/old-test-project
✅ Successfully deleted: aaron-official/abandoned-experiment  
✅ Successfully deleted: aaron-official/temporary-fork

🎉 Batch deletion completed successfully!
```

### Command Line Usage
```bash
# Delete specific repositories
./batch_delete.sh my-old-repo test-project temp-branch
pwsh ./batch_delete.ps1 -Repositories my-old-repo,test-project,temp-branch

# Preview mode (safe testing)
./batch_delete.sh --dry-run repo1 repo2 repo3
pwsh ./batch_delete.ps1 -DryRun -Repositories repo1,repo2,repo3

# Skip confirmations (use with extreme caution!)
./batch_delete.sh --auto-confirm old-repo1 old-repo2
pwsh ./batch_delete.ps1 -AutoConfirm -Repositories old-repo1,old-repo2

# Verbose output for debugging
./batch_delete.sh --verbose --file repos-to-delete.txt
pwsh ./batch_delete.ps1 -Verbose -File repos-to-delete.txt
```

### Configuration File Examples

**repositories.json**
```json
{
  "username": "aaron-official",
  "repositories": [
    "old-project-1",
    "test-repository",
    "abandoned-fork",
    "temporary-experiment"
  ]
}
```

**repos-list.txt**
```
# Repositories to delete
old-website-v1
test-api-project  
outdated-documentation
experimental-feature
# temporary-repo (commented out)
```

## 🛠️ Advanced Configuration

### Environment Variables
```bash
export REPO_NUKE_USERNAME="aaron-official"
export REPO_NUKE_LOG_LEVEL="verbose"
export REPO_NUKE_CONFIRM_REQUIRED="true"
```

### Config File (~/.repo-nuke-config)
```json
{
  "default_username": "aaron-official",
  "confirmation_required": true,
  "max_concurrent_deletions": 5,
  "log_file": "~/.repo-nuke.log",
  "enable_backups": true,
  "rate_limit_delay": 500
}
```

## 🎛️ Command Line Reference

### Core Options
| Option | Description | Example |
|--------|-------------|---------|
| `--interactive` | Launch interactive selection menu | `./batch_delete.sh --interactive` / `pwsh ./batch_delete.ps1 -Interactive` |
| `--dry-run` | Preview mode - no actual deletions | `./batch_delete.sh --dry-run repo1 repo2` / `pwsh ./batch_delete.ps1 -DryRun -Repositories repo1,repo2` |
| `--file <path>` | Load repository list from file | `./batch_delete.sh --file repos.txt` / `pwsh ./batch_delete.ps1 -File repos.txt` |
| `--config <path>` | Use JSON configuration file | `./batch_delete.sh --config config.json` / `pwsh ./batch_delete.ps1 -Config config.json` |
| `--username <user>` | Specify GitHub username | `./batch_delete.sh --username john-doe repo1` / `pwsh ./batch_delete.ps1 -Username john-doe -Repositories repo1,repo2` |
| `--auto-confirm` | Skip confirmation prompts ⚠️ | `./batch_delete.sh --auto-confirm repo1` / `pwsh ./batch_delete.ps1 -AutoConfirm -Repositories repo1,repo2` |
| `--verbose` | Enable detailed output | `./batch_delete.sh --verbose --file repos.txt` / `pwsh ./batch_delete.ps1 -Verbose -File repos.txt` |

> **Note:** In PowerShell, always use `-Repositories repo1,repo2` for multiple repositories. Do not use positional arguments.

### Platform-Specific Scripts
- **Unix/Linux/macOS**: `batch_delete.sh`
- **Windows PowerShell**: `batch_delete.ps1`  
- **Cross-platform Python**: `batch_delete.py`

## 📊 Project Structure

```
repo-nuke/
├── README.md                    # This comprehensive guide
├── LICENSE                      # MIT license
├── batch_delete.sh             # Unix/Linux/macOS script
├── batch_delete.ps1            # Windows PowerShell script
├── batch_delete.py             # Cross-platform Python version
├── .gitignore                  # Git ignore patterns
├── CONTRIBUTING.md             # Contribution guidelines
├── docs/
│   ├── INSTALLATION.md         # Detailed installation guide
│   ├── USAGE.md               # Advanced usage examples
│   ├── TROUBLESHOOTING.md     # Common issues and solutions
│   └── API.md                 # GitHub CLI API reference
└── scripts/
    ├── install-deps.sh        # Dependency installer (Unix)
    └── setup.ps1             # Windows setup script
```

## 🔒 Security & Safety Features

### Built-in Protections
- **Multi-step confirmations** before any destructive operations
- **Repository ownership verification** to prevent cross-account deletions
- **GitHub API permission validation** before starting operations
- **Detailed audit logging** with timestamps for all operations
- **Rate limiting** to comply with GitHub API guidelines
- **Graceful error handling** with rollback information

### Best Practices
1. **Always use dry-run first**: `--dry-run` flag shows exactly what will happen
2. **Start small**: Test with 1-2 repositories before bulk operations
3. **Backup critical repositories**: Clone locally before deletion
4. **Review logs**: Check `~/.repo-nuke.log` for operation history
5. **Use interactive mode**: Safest option for manual repository selection

## 🚨 Troubleshooting

### Common Issues & Solutions

**Authentication Problems**
```bash
# Fix: Refresh GitHub CLI authentication
gh auth refresh -h github.com -s delete_repo
```

**Permission Denied Errors**
```bash
# Fix: Ensure delete_repo scope is granted
gh auth refresh -h github.com -s delete_repo
```

**Repository Not Found**
- Verify repository name spelling and case sensitivity
- Ensure you have access to the repository
- Check if repository was already deleted

**Rate Limit Exceeded**
- RepoNuke includes built-in delays, but for large batches, consider smaller chunks
- GitHub API allows 5000 requests/hour for authenticated users

### Getting Help
- 🐛 [Report Issues](https://github.com/aaron-official/repo-nuke/issues)
- 💬 [Community Discussions](https://github.com/aaron-official/repo-nuke/discussions)
- 📖 [Documentation Wiki](https://github.com/aaron-official/repo-nuke/wiki)
- 📧 [Contact Support](mailto:support@repo-nuke.dev)

## 🤝 Contributing

We welcome contributions! RepoNuke is open source and community-driven.

### Ways to Contribute
- 🐛 **Bug Reports**: Found an issue? Let us know!
- 💡 **Feature Requests**: Have an idea? We'd love to hear it!
- 🔧 **Code Contributions**: Pull requests welcome
- 📖 **Documentation**: Help improve our guides
- 🌍 **Translations**: Make RepoNuke accessible globally

### Quick Contribution Guide
```bash
# Fork and clone
git clone https://github.com/aaron-official/repo-nuke.git
cd repo-nuke

# Create feature branch
git checkout -b feature/awesome-new-feature

# Make changes and test
./batch_delete.sh --dry-run test-repo

# Commit and push
git commit -m "Add awesome new feature"
git push origin feature/awesome-new-feature

# Create pull request on GitHub
```

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines.

## 📄 License

RepoNuke is open source software licensed under the **MIT License**. 

This means you can:
- ✅ Use commercially and personally
- ✅ Modify and distribute
- ✅ Include in private projects
- ✅ Sublicense

See [LICENSE](LICENSE) file for complete terms.

## 🌟 Support the Project

If RepoNuke helped you clean up your GitHub repositories, consider:

- ⭐ **Star this repository** to help others discover it
- 🐛 **Report bugs** to help improve reliability  
- 💡 **Suggest features** to make it even better
- 🤝 **Contribute code** to help build the future
- 📢 **Share with developers** who might benefit

## 📈 Project Stats

- 🚀 **Cross-platform**: Windows, macOS, Linux support
- 🛡️ **Safety-first**: Multiple confirmation layers
- ⚡ **Fast**: Concurrent operations with rate limiting
- 📊 **Reliable**: Comprehensive error handling and logging
- 🎯 **User-friendly**: Interactive mode for easy selection

---

<div align="center">

### 🚀 Ready to clean up your GitHub repositories? 

**[Download RepoNuke](https://github.com/aaron-official/repo-nuke/releases) • [View Documentation](https://github.com/aaron-official/repo-nuke/wiki) • [Join Community](https://github.com/aaron-official/repo-nuke/discussions)**

*Nuclear-powered repository cleanup for professional developers*

</div>

---

**⚠️ Remember**: Repository deletion is permanent. Always backup important code before using RepoNuke!