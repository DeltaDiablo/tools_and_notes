# Git Rebase Options with Examples

- `--interactive` or `-i`: Start an interactive rebase session.
    ```sh
    git rebase -i HEAD~3
    ```
- `--onto <newbase>`: Rebase starting from a specific commit.
    ```sh
    git rebase --onto master feature-branch
    ```
- `--continue`: Resume rebase after resolving conflicts.
    ```sh
    git rebase --continue
    ```
- `--abort`: Cancel the rebase and restore the original branch.
    ```sh
    git rebase --abort
    ```
- `--skip`: Skip the current patch and continue rebasing.
    ```sh
    git rebase --skip
    ```
- `--autostash`: Automatically stash changes before rebasing.
    ```sh
    git rebase --autostash master
    ```
- `--keep-empty`: Preserve empty commits during rebase.
    ```sh
    git rebase --keep-empty master
    ```
- `--root`: Rebase all commits starting from the root.
    ```sh
    git rebase --root master
    ```
- `--exec <command>`: Run a command after each commit.
    ```sh
    git rebase -i --exec "npm test" HEAD~5
    ```
- `--quiet` or `-q`: Suppress output.
    ```sh
    git rebase -q master
    ```
- `--verbose` or `-v`: Show more output.
    ```sh
    git rebase -v master
    ```

Refer to `git rebase --help` for more details.