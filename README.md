# `__project_name__`

`__project_description__`

This repository was created from the
[anselmes/repository](https://github.com/anselmes/repository) template. It
ships with CI, linting, release automation, a dev container and a small PKI
toolchain, so a new project starts with the same baseline as every other
repository.

## Features

- **CI**: super-linter, Trivy and OpenSSF Scorecard run on every push, and
  anselmes/cicd's bot handles Dependabot merges and draft releases
  (`.github/workflows/ci.yml`).
- **Release**: a pushed `v*` tag publishes the GitHub Release
  (`.github/workflows/release.yml`). Workflow actions are pinned through
  `.github/workflows/actions.lock`.
- **Repository automation**: Dependabot, PR labeler and reviewer auto-assignment
  (`.github/dependabot.yml`, `labeler.yml`, `auto_assign.yml`).
- **Quality gates**: Trunk (`.trunk/`), pre-commit and commitlint enforce
  linting, formatting and conventional commits.
- **Dev container**: Ubuntu 24.04 workspace with the recommended VS Code
  extensions (`.devcontainer/`).
- **PKI helpers**: `make` targets generate a root CA, an intermediate CA and TLS
  certificates with `cfssl`, configured by `config/cert.yaml`.

## Prerequisites

- `git`, `gh`, `gnupg` and `pinentry`, with a configured signing key
  (`user.signingkey`)
- `cfssl` and `yq` for the PKI targets
- Docker, to use the dev container
- Homebrew (macOS), to install the tools above in one step

```bash
brew bundle --file hack/Brewfile
```

> [!IMPORTANT]
> Every commit and release tag must be cryptographically signed. Enable it once
> with `git config commit.gpgsign true`.

## Installation

Create a repository from the template, then clone it.

```bash
gh repo create <owner>/<name> --template anselmes/repository --private --clone
cd <name>
```

Then work through the [TODO](#todo-replace-placeholders) list below.

## Usage

Run `make help` to list the targets. Output is written to `pki/`, which is
git-ignored.

```bash
make help    # show available targets
make config  # generate the OpenSSL/cfssl config from config/cert.yaml
make rootca  # generate the root CA
make ca      # generate the intermediate CA and bundle
make cert    # generate TLS certificates and bundle (default target)
make clean   # remove generated files in pki/
```

> [!CAUTION]
> Never commit anything under `pki/`, nor any key, certificate or `.env` file.

## Development

Open the repository in the dev container, or install the tools from
[Prerequisites](#prerequisites) locally.

```bash
trunk check   # lint
trunk fmt     # format
```

- Write commit messages in the conventional commit format (`feature:`, `fix:`,
  `chore:`), and sign every commit with `git commit -S`.
- Credit contributing AI agents with a `Co-authored-by` trailer.
- Open multi-part work as a stack of PRs with `gh stack`.

## TODO: Replace placeholders

Placeholders use the `__name__` form. Find every remaining one with:

```bash
grep -rnE "__[a-z_]+__" --exclude-dir=.git .
```

- [ ] `README.md`: replace `__project_name__` and `__project_description__`, and
      adjust the sections above to describe the project
- [ ] `CODEOWNERS`: replace `__owner__` with the GitHub user or team
- [ ] `SECURITY_CONTACTS`: replace `__owner__` with the security contact
- [ ] `.github/auto_assign.yml`: replace `__owner__` under both `reviewers` and
      `assignees`
- [ ] `hack/copyright.txt`: replace `__license__`, `__year__` and `__author__`
- [ ] `Makefile`: change `NAME := repository` to the project name
- [ ] `config/cert.yaml`: replace `__country__`, `__locality__`, `__state__`
      and `__organization__` in the `names` of `ca`, `intermediate` and `tls`,
      and review `OU`, `tls.CN` and `tls.hosts` (defaults are `localhost` and
      `127.0.0.1`)
- [ ] Delete this section

## License

This project is licensed under the GNU General Public License v3.0 - see
[LICENSE](LICENSE) for details.
