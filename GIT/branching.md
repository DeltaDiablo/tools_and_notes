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

## Tips

- Use descriptive branch names (e.g., `bugfix/login-error`, `feature/dashboard-ui`).
- Always push your branch to remote to collaborate with others.
