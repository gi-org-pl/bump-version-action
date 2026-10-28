# bump-version-action

A GitHub Action that sets the version in `package.json` one patch above the base branch and pushes the commit to the pull request branch, so that pull requests opened by Dependabot are ready to release.

## Requirements

- The pull request branch checked out with `ref: ${{ github.head_ref }}` and a token that can push to it.
- A GitHub App token for the checkout, from `actions/create-github-app-token` with `permission-contents: write`. A push made with `GITHUB_TOKEN` does not start new workflow runs, so the checks would not run on the bumped commit.
- On Dependabot pull requests, the app credentials stored as Dependabot secrets, because workflows started by Dependabot cannot read Actions secrets.
- `jq`, `npm` and `gh` on the `PATH`, as on GitHub-hosted runners.

## Usage

```yaml
- name: Bump the patch version
  uses: gi-org-pl/bump-version-action@v1
  with:
    app-slug: ${{ steps.app-token.outputs.app-slug }}
```

## Inputs

| Input               | Description                                                       | Required | Default                   |
|---------------------|-------------------------------------------------------------------|----------|---------------------------|
| `app-slug`          | Slug of the GitHub App whose bot authors the commit               | No       | `github-actions`          |
| `base-ref`          | Branch whose version is bumped                                    | No       | `${{ github.base_ref }}`  |
| `working-directory` | Directory with the `package.json` file                            | No       | `.`                       |

## Example workflow

```yaml
name: bump-version

on:
  pull_request:

concurrency:
  group: bump-version-${{ github.event.pull_request.number }}
  cancel-in-progress: true

jobs:
  bump:
    if: github.actor == 'dependabot[bot]'
    runs-on: ubuntu-24.04
    timeout-minutes: 5
    permissions:
      contents: read
    steps:
      - name: Create GitHub App token
        id: app-token
        uses: actions/create-github-app-token@v3
        with:
          client-id: ${{ secrets.VERSION_BUMP_APP_CLIENT_ID }}
          private-key: ${{ secrets.VERSION_BUMP_APP_PRIVATE_KEY }}
          permission-contents: write

      - name: Checkout pull request branch
        uses: actions/checkout@v7
        with:
          ref: ${{ github.head_ref }}
          token: ${{ steps.app-token.outputs.token }}

      - name: Bump the patch version
        uses: gi-org-pl/bump-version-action@v1
        with:
          app-slug: ${{ steps.app-token.outputs.app-slug }}
```

## How it works

The action reads the version from `package.json` on the base branch and increases its patch number, so `1.4.2` becomes `1.4.3`. If the pull request branch already has this version, the action does nothing, so it can run on every push. Otherwise it sets the version with `npm version`, which also updates `package-lock.json`, and pushes a commit authored by the app's bot.

When the base branch moves on, the next run bumps the pull request again, one patch above the new base version. The commit message ends with `[dependabot skip]`, so Dependabot can still rebase and update the pull request.

## Authors

Action author is [Oskar Barcz](https://github.com/oskarbarcz), CTO of **[Generacja Innowacja](https://gi.org.pl)** —
Poland's first technology-first NGO.

## License

MIT
