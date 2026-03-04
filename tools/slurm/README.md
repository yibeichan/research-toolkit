# SLURM Submit Tracking (`sbatch_track.sh`)

`tools/slurm/sbatch_track.sh` is a thin wrapper around `sbatch`.
It submits your job normally, then appends one TSV row with submission metadata.

## What It Logs
Columns in the history TSV:

`timestamp`, `user`, `host`, `cwd`, `git_sha`, `job_id`, `status`, `script`, `array`, `time`, `mem`, `partition`, `command`

## Default History Location
By default, history is written per project repo at:

`<repo_root>/logs/slurm_history.tsv`

Note: in this repo, `logs/` is gitignored, so history is local and not committed.

## Basic Usage
Use it exactly where you would normally use `sbatch`:

```bash
tools/slurm/sbatch_track.sh --array=0-31%8 scripts/03c_run_rslds.sh
```

## Project-Specific Path Controls
You can override where history is written.

### Option 1: CLI flags
```bash
tools/slurm/sbatch_track.sh --track-dir /path/to/project/logs --array=0-31%8 scripts/03c_run_rslds.sh
```

```bash
tools/slurm/sbatch_track.sh --track-file /path/to/project/logs/slurm_history.tsv --array=0-31%8 scripts/03c_run_rslds.sh
```

### Option 2: Environment variables
```bash
export SLURM_HISTORY_DIR=/path/to/project/logs
# or
export SLURM_HISTORY_FILE=/path/to/project/logs/slurm_history.tsv
```

## Make It Your Default `sbatch`
Add to `~/.bashrc`:

```bash
sbatch(){ /orcd/home/002/yibei/research-toolkit/tools/slurm/sbatch_track.sh "$@"; }
```

Reload shell:

```bash
source ~/.bashrc
```

## Behavior Notes
- Exit code is forwarded from `sbatch`.
- `status=ok` when submit succeeds and job id is parsed.
- `status=error` when `sbatch` fails.
- `status=unknown` when submit output does not include a parsable job id.
- `--track-help` prints wrapper help.
