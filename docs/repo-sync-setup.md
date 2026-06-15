# Repo Sync Setup — Mirroring My Projects Across Machines

> My notes from setting this up on **2026-06-15**. Covers the strategy, the script,
> what I learned about Git/GitHub, and the things I deliberately left for later.

---

## 1. The Problem & The Strategy

**Problem:** I want my coding projects on both my desktop and laptop, kept in sync.
I used to sync folders with cloud drives (Dropbox/iCloud), but **cloud drives corrupt
Git repositories** — the cloud client and Git both manage file state independently and
fight each other inside the hidden `.git` folder.

**The strategy (how professionals do it):**

1. **Git itself is the sync mechanism.** Every project is a repo on GitHub.
2. **GitHub is the source of truth.** My laptop/desktop are just *disposable clones.*
3. **One folder for all projects:** `~/code` (not split across folders, not loose in `~`).
4. **A script clones my active projects automatically** on any machine.

Daily workflow once it's set up:
- `git push` on one machine → `git pull` on the other. That's the whole sync story.

---

## 2. The Strategy for Setting Up a New (or Clean) Machine

My dotfiles use **dotbot** (`install.conf.yaml` + the `install` script). Setup runs a
series of shell steps in order. I added repo-cloning as **Step 7**.

**On a brand-new machine:**
```sh
# 1. Get my dotfiles
git clone git@github.com:otrai/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
# 2. Run the installer — Homebrew (installs gh), SSH, ..., then Step 7 clones my repos
./install
```

**On my existing laptop (just grab new/updated setup):**
```sh
cd ~/.dotfiles
git pull                      # get the latest dotfiles, including new scripts
./scripts/setup_repos.zsh     # clone any repos I don't have yet into ~/code
```

The clone step is **idempotent** — re-running it only clones repos I'm missing and skips
the ones I already have. So it's safe to run anytime; it doubles as "grab my new repos."

---

## 3. The Script — `scripts/setup_repos.zsh` (How To Write It)

The whole script with notes on every part. This is the thing I most want to understand.

```zsh
#!/bin/zsh                       # shebang: run this file with zsh
set -euo pipefail               # safety: stop on errors, unset vars, failed pipes

# ── Settings (the ONLY lines I'd ever change) ──
CODE_DIR="$HOME/code"           # where my projects live  ← single source of truth
GITHUB_USER="otrai"             # which GitHub account to mirror
EXCLUDE=("dotfiles")            # repos NOT to clone here (dotfiles lives in ~/.dotfiles)

# ── Preflight checks ──
if ! command -v gh >/dev/null 2>&1; then   # is the GitHub CLI installed?
  echo "❌ gh not found"; exit 1
fi
if ! gh auth status >/dev/null 2>&1; then  # am I logged in to GitHub?
  gh auth login                            # if not, start the login flow
fi

mkdir -p "$CODE_DIR"            # create ~/code if it doesn't exist (-p = no error if it does)

# ── Discover active repos (NO manual list to maintain) ──
repos=$(gh repo list "$GITHUB_USER" --source --no-archived --limit 1000 \
        --json name --jq '.[].name')

# ── Loop over each repo name and clone the missing ones ──
for name in ${(f)repos}; do     # ${(f)...} = zsh: split the text on newlines
  # skip anything in the EXCLUDE list
  skip=0
  for ex in "${EXCLUDE[@]}"; do
    [[ "$name" == "$ex" ]] && skip=1
  done
  (( skip )) && { echo "⏭️  skip $name"; continue; }

  dest="$CODE_DIR/$name"
  if [[ -d "$dest" ]]; then     # [[ -d ... ]] = "does this directory exist?"
    echo "✅ $name already present"
  else
    git clone "git@github.com:$GITHUB_USER/$name.git" "$dest"   # clone over SSH
  fi
done
```

### Shell concepts I learned writing this

| Piece | What it means |
|---|---|
| `#!/bin/zsh` | "shebang" — tells the OS which interpreter runs the file |
| `set -euo pipefail` | fail fast: `-e` exit on error, `-u` error on undefined var, `pipefail` catch errors in pipes |
| `VAR="value"` | define a variable; use it as `$VAR` or `"$VAR"` (quotes preserve spaces) |
| `command -v gh` | check whether a command exists (returns success/failure, no output with `>/dev/null`) |
| `mkdir -p` | create a folder; `-p` = don't error if it already exists |
| `${(f)repos}` | zsh-specific: split a string into a list on each newline |
| `for x in LIST; do ... done` | run the same block once per item |
| `[[ -d "$path" ]]` | test if a directory exists (`-f` would test a file) |
| `&&` / `\|\|` | "and then if success" / "or else if failure" |
| `continue` | skip to the next loop iteration |
| `>/dev/null 2>&1` | throw away normal output **and** error output (just want the exit code) |

### Why the script is built this way (design choices)

- **Settings block at the top = single source of truth.** If I rename the folder or add an
  exclusion, I change one line, not the whole script.
- **`gh repo list --source --no-archived`** is the magic: `--source` drops forks,
  `--no-archived` drops finished/archived repos. So it returns *only my active projects* —
  **no manifest/list to maintain.**
- **Idempotent** (`if [[ -d ]] ... else clone`): safe to re-run forever.
- **Clones over SSH** (`git@github.com:...`) to match my 1Password SSH agent setup.

### Wiring it into the installer (`install.conf.yaml`)

Added as the last entry under `- shell:` (Step 7). It must come *after* Homebrew (installs
`gh`) and SSH (sets up my key). YAML is indentation-sensitive — copy an existing block to
get the spacing right.

```yaml
    # 📦 Step 7: Clone active GitHub repositories into ~/code
    - command: ./scripts/setup_repos.zsh
      stdout: true
      stderr: true
```

---

## 4. What I Learned About Git & GitHub

### Git repos are self-contained
- Every repo has a hidden `.git` folder holding **all** history, settings, and the remote URL.
- **Moving the whole project folder doesn't affect Git at all** — Git tracks files *relative
  to its own root*, and the remote is a **URL** (`git@github.com:otrai/x.git`), not a disk path.
- Rule of thumb: **Git only watches what happens *inside* its own walls.**
  - Move the whole repo folder → Git doesn't notice. (Nothing to commit.)
  - Move/rename a file *inside* the repo → Git notices, and I commit that.

### The core Git workflow (status → add → commit → push)
| Command | What it does |
|---|---|
| `git status` | show what changed; what's staged; whether I'm in sync with GitHub |
| `git add <files>` | **stage** changes — pick what goes into the next commit (a holding pen) |
| `git commit -m "..."` | **record a snapshot** locally (does NOT upload) |
| `git push` | **upload** local commits to GitHub (this is what reaches other machines) |
| `git pull` | download commits from GitHub onto this machine |

- **File states:** *untracked* (new, Git ignores it until `add`ed) → *staged* → *committed*.
  `modified` = a tracked file changed but not yet staged.
- `git status -sb` shows a short summary like `## main...origin/main [ahead 1]`
  = "I have 1 commit GitHub doesn't have yet" (i.e. I still need to `push`).

### Commit messages
- **One commit = one logical change** (not one-per-file). My 3 files (Brewfile, script,
  install.conf) were all one *feature*, so → one commit.
- Format: **subject line** (short, states intent) + blank line + **body** (bullets listing
  the specifics). Example I used:
  ```
  feat: clone active GitHub repos into ~/code on setup

  - Add gh (GitHub CLI) to Brewfile for repo discovery
  - Add scripts/setup_repos.zsh to clone active repos into ~/code; idempotent
  - Wire setup_repos.zsh into install.conf.yaml as Step 7
  ```
- I use the `feat:` / `refactor:` / `wip:` ("conventional commits") prefixes.

### The GitHub CLI (`gh`)
- `gh` is to GitHub what `brew` is to Homebrew: a **command-line tool** for the service.
- `gh auth login` — log in (chose **SSH** protocol + browser login to match my setup).
- `gh auth status` — check login + see **token scopes** (permissions).
- `gh auth refresh -h github.com -s delete_repo` — add a permission (deleting needs it; it's
  blocked by default for safety).
- `gh repo list otrai` — list my repos (the heart of the clone script).
- `gh repo delete otrai/<name>` — delete a repo (**permanent!**).
- `gh repo archive otrai/<name>` / `gh repo unarchive ...` — freeze/unfreeze a repo.

### Archive vs Delete (important distinction)
- **Archive** = mark read-only, **reversible**, deletes nothing. Good for "finished but maybe
  useful later." Keeps it out of `~/code` (because the script uses `--no-archived`).
- **Delete** = **permanent.** Only for true throwaway.
- For the script's purposes, both keep a repo out of `~/code` — the choice is purely about
  whether I want it gone from GitHub forever.

### Other useful facts
- A folder like `~/code` is **NOT** a repo — it's just a container holding repos.
- Untracked files are **not backed up** until `add` + `commit` + `push`. (My `.m` files were
  local-only — a move preserved them, but a re-clone would have lost them. That's why I
  *moved* folders instead of re-cloning.)
- SSH auth goes through my **1Password SSH agent**; clones use `git@github.com:...` URLs.

---

## 5. Decisions We Made (and Why)

| Decision | Why |
|---|---|
| One `~/code` folder | Not two (GitHub can't tell them apart), not loose in `~` (clutter). One folder = clean + maps 1:1 to my GitHub list. |
| `gh` auto-discovery, not a manual list | I'd forget to update a list. Discovery has nothing to maintain. |
| Archive/delete to define "active" | GitHub holds the active-vs-finished state, so there's no local list. |
| **Flat** layout now (`~/code/<repo>`) | Simpler; deep `host/account/repo` nesting is for multiple accounts I don't have yet. Migrating later is cheap (it's just a re-clone). |
| Cleaned up GitHub (deleted 14 junk repos) | Fresh start; only 4 real projects remain. |

---

## 6. Future / Deferred — Things To Do or Decide Later

Stuff we intentionally did **not** do today:

### Soon / housekeeping
- [ ] **Finish the folder move (Part 2)** if not done: `mv ~/developer/asu-cse-110-205 ~/code/`
      then `rm -rf ~/developer ~/engineering`, then restart Claude from `~/code/asu-cse-110-205`.
- [ ] **Back up my schoolwork** — the untracked `.m` files in `~/code/eee304-lab1`
      (`eee304_lab1.m`, `test_script.m`) and `~/code/matlab` (`functions/addTwo.m`) are
      local-only. Commit + push them (after Lab 1) so they reach my laptop.
- [ ] **On the laptop:** `cd ~/.dotfiles && git pull` then run `./scripts/setup_repos.zsh`.
- [ ] Tiny cosmetic cleanup in `install.conf.yaml`: a blank line has trailing spaces and the
      file has no final newline (harmless).

### Scaling the script later (only when needed)
- [ ] **Multiple GitHub accounts/orgs** (e.g. a job adds me to an org): change the script to
      loop over an `ACCOUNTS=("otrai" "other")` array and nest the path as
      `~/code/github.com/<account>/<repo>`. ~5-line change because the structure is in variables.
- [ ] **A different host** (GitLab/Bitbucket): `gh` only talks to GitHub. That's the trigger to
      switch to **`ghq`** — a tool that clones any host into the nested layout automatically.
- [ ] **`zoxide`** (optional): a smarter `cd` that jumps to folders by name (`z asu`). Makes deep
      nested paths painless. Nice quality-of-life, not required.

### Claude / workflow
- [ ] Decide **where to launch Claude**: per-project (`~/code/<project>`) for focused coding vs
      `~/code` for cross-project work. Memory is stored *per launch directory*.
- [ ] Decide **which memories go where**: general preferences → `~/.claude/CLAUDE.md` (applies
      everywhere); project-specific facts → that project's memory. (Left this to think about.)

---

## 7. Quick Command Cheat-Sheet

```sh
# --- Daily Git ---
git status                      # what changed?
git add <files>                 # stage changes
git commit -m "subject"         # record snapshot (local)
git push                        # upload to GitHub
git pull                        # download from GitHub

# --- GitHub CLI ---
gh auth status                  # am I logged in? what permissions?
gh repo list otrai              # list my repos
gh repo archive otrai/<name>    # freeze a repo (reversible)
gh repo delete  otrai/<name>    # delete a repo (PERMANENT)

# --- This setup ---
./scripts/setup_repos.zsh       # clone my active repos into ~/code (idempotent)
```
