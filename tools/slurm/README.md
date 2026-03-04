# SLURM Submit Tracking (`sbatch_track.sh`)

`tools/slurm/sbatch_track.sh` is a thin wrapper around `sbatch`.
It submits your job normally, then appends one TSV row with submission metadata.

## What It Logs
Columns in the history TSV:

`timestamp`, `user`, `host`, `cwd`, `git_sha`, `job_id`, `status`, `script`, `array`, `time`, `mem`, `partition`, `command`

## Default History Location
By default, history is written to:

`<repo_root>/scripts/slurm_history`

## Basic Usage
Use it exactly where you would normally use `sbatch`:

```bash
tools/slurm/sbatch_track.sh --array=0-31%8 scripts/03c_run_rslds.sh
```

## Override History Path
Set `SLURM_HISTORY_FILE` when calling the wrapper:

```bash
SLURM_HISTORY_FILE=/path/to/project/logs/slurm_history.tsv \
  tools/slurm/sbatch_track.sh --array=0-31%8 scripts/03c_run_rslds.sh
```

## Make It Your Default `sbatch`
Add to `~/.bashrc` for per-project history files automatically:

```bash
sbatch() {
  local repo_root
  repo_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  mkdir -p "$repo_root/logs"
  SLURM_HISTORY_FILE="$repo_root/logs/slurm_history.tsv" \
    /orcd/home/002/yibei/research-toolkit/tools/slurm/sbatch_track.sh "$@"
}
```

Reload shell:

```bash
source ~/.bashrc
```

After this, normal submits still work:

```bash
sbatch scripts/03b_pca4rslds.sh
sbatch --array=0-31%8 scripts/03b_pca4rslds.sh
```

Each repo gets its own file at:

`<repo_root>/logs/slurm_history.tsv`

## Behavior Notes
- Exit code is forwarded from `sbatch`.
- `status=ok` when submit succeeds and job id is parsed.
- `status=error` when `sbatch` fails.
- `status=unknown` when submit output does not include a parsable job id.
