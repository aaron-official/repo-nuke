# Advanced Usage Examples

> **Note:** In PowerShell, always use `-Repositories repo1,repo2` for multiple repositories. Do not use positional arguments.

## Interactive Mode (Recommended)
```sh
./batch_delete.sh --interactive
# or
pwsh ./batch_delete.ps1 -Interactive
# or
python batch_delete.py --interactive
```

## Delete Specific Repositories
```sh
./batch_delete.sh repo1 repo2 repo3
pwsh ./batch_delete.ps1 -Repositories repo1,repo2,repo3
python batch_delete.py repo1 repo2 repo3
```

## Use a File List
```sh
echo -e "repo1\nrepo2\nrepo3" > repos.txt
./batch_delete.sh --file repos.txt
pwsh ./batch_delete.ps1 -File repos.txt
python batch_delete.py --file repos.txt
```

## Use a JSON Config
```json
{
  "username": "aaron-official",
  "repositories": ["repo1", "repo2", "repo3"]
}
```
```sh
./batch_delete.sh --config config.json
pwsh ./batch_delete.ps1 -Config config.json
python batch_delete.py --config config.json
```

## Dry Run (Preview)
```sh
./batch_delete.sh --dry-run repo1 repo2
pwsh ./batch_delete.ps1 -DryRun -Repositories repo1,repo2
python batch_delete.py --dry-run repo1 repo2
```

## Skip Confirmations (Dangerous!)
```sh
./batch_delete.sh --auto-confirm repo1
pwsh ./batch_delete.ps1 -AutoConfirm -Repositories repo1,repo2
python batch_delete.py --auto-confirm repo1
```

---

See the README for more details and safety tips.
