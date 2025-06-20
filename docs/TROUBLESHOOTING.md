# Troubleshooting

## Authentication Problems
- **Error:** Not authenticated with GitHub
- **Solution:**
  ```sh
  gh auth login
  gh auth refresh -h github.com -s delete_repo
  ```

## Permission Denied
- **Error:** Insufficient permissions to delete repositories
- **Solution:**
  ```sh
  gh auth refresh -h github.com -s delete_repo
  ```

## Repository Not Found
- **Error:** Repository not found or inaccessible
- **Solution:**
  - Check repository name spelling and case
  - Ensure you have access to the repository
  - Confirm the repository still exists

## Rate Limit Exceeded
- **Error:** API rate limit exceeded
- **Solution:**
  - Wait and retry after some time
  - Reduce batch size

## Script Not Executable (Unix)
- **Error:** Permission denied
- **Solution:**
  ```sh
  chmod +x batch-delete.sh scripts/install-deps.sh
  ```

## Still Need Help?
- Open an issue at https://github.com/aaron-official/repo-nuke/issues
