# GitHub CLI API Reference

RepoNuke uses the official [GitHub CLI (gh)](https://cli.github.com/) for all repository operations.

## Key Commands Used

### Authentication
- `gh auth login` — Authenticate with GitHub
- `gh auth status` — Check authentication status
- `gh auth refresh -h github.com -s delete_repo` — Ensure delete_repo scope

### Repository Listing
- `gh repo list <username> --limit 100 --json name --jq '.[].name'` — List repositories for a user

### Repository Deletion
- `gh repo delete <username>/<repo> --yes` — Delete a repository (no prompt)

### Repository View (Validation)
- `gh repo view <username>/<repo> --json name` — Check if a repository exists and is accessible

## More Info
- See the [GitHub CLI documentation](https://cli.github.com/manual/) for advanced usage and options.
