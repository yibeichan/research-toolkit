# SLURM Submit Tracking (`sbatch_track.sh`)

`sbatch_track.sh` is a thin wrapper around `sbatch`.
It submits your job normally, then appends one TSV row with submission metadata.

## What It Logs
Columns in the history TSV:

`timestamp`, `user`, `host`, `cwd`, `git_sha`, `job_id`, `status`, `script`, `array`, `time`, `mem`, `partition`, `command`

## Basic Usage
Use it exactly where you would normally use `sbatch`:

```bash
tools/slurm/sbatch_track.sh --array=0-31%8 scripts/your_slurm_script.sh
```

The folder `scripts` is situational. I like to keep  my scripts in a folder called `scripts` per project. You could choose other names.

## Override History Path
Set `SLURM_HISTORY_FILE` when calling the wrapper (only if you want all your slurm history in one place, rather than project/repo specific):

```bash
SLURM_HISTORY_FILE=/path/to/logs/slurm_history.tsv \
  sbatch_track.sh --array=0-31%8 scripts/your_slurm_script.sh
```

## Make It Your Default `sbatch`
Add to `~/.bashrc` for per-project history files automatically:

```bash
sbatch() {
  local repo_root
  repo_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  mkdir -p "$repo_root/logs"
  SLURM_HISTORY_FILE="$repo_root/logs/slurm_history.tsv" \
    the_absolute_path_to/sbatch_track.sh "$@"
}
```

Reload shell:

```bash
source ~/.bashrc
```

After this, normal submits still work:

```bash
cd your_project_folder
sbatch scripts/your_slurm_script.sh
sbatch --array=0-31 scripts/your_slurm_script.sh
```

Each repo/project gets its own file at:

`<repo_root>/logs/slurm_history.tsv`

which will look like
# Job Submission Log

| timestamp | user | host | cwd | git_sha | job_id | status | script | array | time | mem | partition | command |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 2026-03-04T15:31:40-05:00 | yourname | nodeXXXX | your_project_folder | 7a32260 | 10038147 | ok | scripts/your_slurm_script.sh | NA | NA | NA | NA | sbatch scripts/your_slurm_script.shh |
| 2026-03-04T15:31:44-05:00 | yourname | nodeXXXX | your_project_folder | 7a32260 | 10038152 | ok | scripts/your_slurm_script.sh | 0-31 | NA | NA | NA | sbatch --array=0-31 scripts/your_slurm_script.sh |

`nodeXXXX` will be HPC specific.

## Behavior Notes
- Exit code is forwarded from `sbatch`.
- `status=ok` when submit succeeds and job id is parsed.
- `status=error` when `sbatch` fails.
- `status=unknown` when submit output does not include a parsable job id.
