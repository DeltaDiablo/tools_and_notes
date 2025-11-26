# Creating a New Git Branch

This guide explains how to create a new branch in Git, with examples.

## 1. List Existing Branches

```bash
git branch
```

## 2. Create a New Branch

Replace `feature-branch` with your desired branch name.

```bash
git branch feature-branch
```

## 3. Switch to the New Branch

```bash
git checkout feature-branch
```

Or, combine creation and checkout in one step (Git 2.23+):

```bash
git switch -c feature-branch
```

## 4. Push the New Branch to Remote

```bash
git push -u origin feature-branch
```

## Example Workflow

```bash
git branch add-login
git checkout add-login
# Make changes and commit
git push -u origin add-login
```

## 5. merge another branch onto your branch
To merge another branch (e.g., `other-branch`) onto your current branch:

```bash
git checkout your-branch
git merge other-branch
```

- Resolve any merge conflicts if prompted.
- Commit the merge if necessary.
- Push your updated branch to remote:

```bash
git push
```


## 6. rebase another branch onto your branch

To rebase another branch (e.g., `other-branch`) onto your current branch:

```bash
git checkout your-branch
git rebase other-branch
```

- If there are conflicts, resolve them and continue the rebase:

```bash
git add .
git rebase --continue
```

- After a successful rebase, push your branch (you may need to force-push if the history changed):

```bash
git push --force-with-lease
```

## Tips

- Use descriptive branch names (e.g., `bugfix/login-error`, `feature/dashboard-ui`).
- Always push your branch to remote to collaborate with others.
