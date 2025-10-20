# Canceling a Git Rebase

When working with Git, you may need to undo a rebase operation due to conflicts, rebasing onto the wrong branch, or simply changing your mind. Below are common methods to cancel or undo a Git rebase.

## 1. Using ORIG_HEAD

Git sets `ORIG_HEAD` to the original tip of your branch before a rebase or merge. You can use it to reset your branch:

```sh
# View current commits
git log HEAD

# Start a rebase (example)
git rebase feature1

# Check ORIG_HEAD
git log ORIG_HEAD

# Reset to ORIG_HEAD
git reset --hard ORIG_HEAD
```

> **Note:** This works only if `ORIG_HEAD` hasn't been changed by another operation since the rebase.

## 2. Using Git Reflog

`git reflog` records all changes to branch tips and references. You can use it to find and reset to a previous commit:

```sh
# List reflog entries
git reflog

# Reset to a previous commit (replace {n} with the correct index)
git reset --hard HEAD@{n}
```

For example:
```sh
git reset --hard HEAD@{3}
```

This method offers more control and is useful for advanced scenarios.

## 3. Aborting a Rebase in Progress

If you are in the middle of a rebase and want to stop:

```sh
git rebase --abort
```

This command aborts the rebase and restores your branch to its previous state.
