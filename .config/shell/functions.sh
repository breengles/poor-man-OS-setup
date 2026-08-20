#!/usr/bin/env bash

# Run the Hermes Agent TUI inside the docker container (see ~/hermes-docker).
# First arg, if a directory, becomes the session CWD; otherwise PWD is used.
# That directory must be bind-mounted into the container — see the `volumes:`
# block in docker-compose.yaml.
function hermes {
  local container="${HERMES_CONTAINER:-hermes}"
  local dir

  if [ $# -gt 0 ] && [ -d "$1" ]; then
    dir="$(cd "$1" && pwd)"
    shift
  else
    dir="$PWD"
  fi

  if ! docker ps --format '{{.Names}}' | grep -qx "$container"; then
    echo "container '$container' is not running — try: (cd ~/hermes-docker && docker compose up -d)" >&2
    return 1
  fi

  docker exec -it \
    -e TERM="$TERM" -e COLORTERM="$COLORTERM" \
    -w "$dir" \
    "$container" /opt/hermes/.venv/bin/hermes "$@"
}

function calcimages {
  find "$1" -type f \( -name \*.jpg -o -name \*.jpeg -o -name \*.png \) | wc -l
}

function calcjson {
  find "$1" -type f -name "*.json" | wc -l
}

function _run {
  local label="$1"
  shift
  echo "========== updating $label =========="
  echo "$*"
  eval "$@"
  echo
}

function update {
  if type zinit &>/dev/null; then
    _run "zinit" "zinit self-update && zinit update --all --parallel"
  fi

  if [ -x "$(command -v brew)" ]; then
    _run "brew packages" "brew update && brew upgrade"
    echo "The following packages were NOT upgraded (PINNED):"
    brew list --pinned
    echo
  fi

  if [[ $(hostname) != *"login"* ]]; then
    if [ -x "$(command -v apt)" ]; then
      _run "apt packages" "sudo apt update && sudo apt upgrade"
    fi
  fi

  if [ -x "$(command -v cargo)" ]; then
    _run "cargo" "cargo install-update --all --jobs 8"
  fi
}

function act {
  local venv_path=".venv"
  
  # Override venv_path if provided as an argument
  if [ $# -eq 1 ]; then
    venv_path="$1"
  fi
  
  if [ -d "$venv_path" ]; then
    source "$venv_path/bin/activate"
  else
    echo "Virtual environment '$venv_path' does not exist."
  fi
}

# some stuff for remote cluster
_SLURM_JOB_SUMMARY_AWK='{
  total++;
  counts[$1]++;
} END {
  running = counts["RUNNING"] + 0;
  pending = counts["PENDING"] + 0;
  completing = counts["COMPLETING"] + 0;
  other = total - running - pending - completing;
  printf "Jobs: %d R=%d P=%d C=%d", total, running, pending, completing;
  if (other > 0) printf " O=%d", other;
  printf "\n";
}'
_SLURM_QUEUE_FMT="%.16i %.16P %45j %.3T %.12M %18N"

function q {
  sinfo
  echo ""
  squeue --user="$(whoami)" --format="$_SLURM_QUEUE_FMT"
  echo ""
  squeue --user="$(whoami)" --array --noheader -o '%T' | awk "$_SLURM_JOB_SUMMARY_AWK"
}

function qq {
  watch -n 1 "squeue --user=\$(whoami) --array --noheader -o '%T' | awk '$_SLURM_JOB_SUMMARY_AWK'; echo ''; squeue --user=\$(whoami) --format='$_SLURM_QUEUE_FMT'"
}

# scancel tab completion: completes job IDs with job name as description
if [ -x "$(command -v scancel)" ]; then
  if [ -n "$ZSH_VERSION" ]; then
    function _scancel_complete {
      local -a job_specs
      while IFS='|' read -r jobid jobname; do
        job_specs+=("${jobid}:${jobname}")
      done < <(squeue --user="$(whoami)" --noheader -o '%i|%j' 2>/dev/null)
      _describe 'job' job_specs
    }
    compdef _scancel_complete scancel
  elif [ -n "$BASH_VERSION" ]; then
    function _scancel_complete {
      local cur="${COMP_WORDS[COMP_CWORD]}"
      COMPREPLY=($(compgen -W "$(squeue --user="$(whoami)" --noheader -o '%i' 2>/dev/null)" -- "$cur"))
    }
    complete -F _scancel_complete scancel
  fi
fi

function gpu {
  if [ -z "$1" ]; then
    echo "Usage: gpu <node-number>" >&2
    return 1
  fi
  ssh "lambda-scalar$1" -t nvitop
}

function gpu_usage {
  if ! command -v squeue >/dev/null 2>&1 || ! command -v scontrol >/dev/null 2>&1; then
    echo "SLURM not found: require squeue and scontrol" >&2
    return 1
  fi

  squeue -t RUNNING -h -o "%i %u %b %P %D %C" | awk '{
      jobid=$1; user=$2; gres=$3; partition=$4; nodes=$5; cpus=$6;
      user_jobs[user]++;
      user_partition_jobs[user,partition]++;
      
      # Track all unique partitions
      all_partitions[partition] = 1;
      
      gpu_count=0;
      
      # Handle normal GRES format (gres:gpu:N)
      if (gres ~ /gpu/) {
          if (match(gres, /gpu:([0-9]+)/, arr)) {
              gpu_count = arr[1];
          } else if (gres ~ /gpu/) {
              gpu_count = 1;
          }
          user_gpus[user] += gpu_count;
          user_partition_gpus[user,partition] += gpu_count;
          job_gpu_found[jobid] = 1;
      }
      # Store job info for later processing of N/A cases
      else if (gres == "N/A") {
          na_jobs[jobid] = user ":" partition;
      }
  } END {
      # For jobs with N/A GRES, get detailed GPU info from scontrol
      for (jobid in na_jobs) {
          split(na_jobs[jobid], info, ":");
          user = info[1];
          partition = info[2];
          
          cmd = "scontrol show job " jobid " | grep -E \"TRES=.*gres/gpu=|TresPerTask=.*gpu:\" | head -1";
          if ((cmd | getline line) > 0) {
              close(cmd);
              gpu_count = 0;
              
              # Look for total GPU allocation in TRES field
              if (match(line, /gres\/gpu=([0-9]+)/, arr)) {
                  gpu_count = arr[1];
              }
              # Fallback: try to extract from TresPerTask if available
              else {
                  cmd2 = "scontrol show job " jobid " | grep TresPerTask";
                  if ((cmd2 | getline line2) > 0) {
                      close(cmd2);
                      cmd3 = "scontrol show job " jobid " | grep NumTasks";
                      if ((cmd3 | getline line3) > 0) {
                          close(cmd3);
                          if (match(line2, /gpu:([0-9]+)/, gpu_per_task) && match(line3, /NumTasks=([0-9]+)/, num_tasks)) {
                              gpu_count = gpu_per_task[1] * num_tasks[1];
                          }
                      }
                  }
              }
              
              if (gpu_count > 0) {
                  user_gpus[user] += gpu_count;
                  user_partition_gpus[user,partition] += gpu_count;
              }
          }
      }
      
      # Create sorted array of partitions
      n_partitions = 0;
      for (p in all_partitions) {
          partition_list[++n_partitions] = p;
      }
      # Sort partitions
      for (i = 1; i <= n_partitions; i++) {
          for (j = i + 1; j <= n_partitions; j++) {
              if (partition_list[i] > partition_list[j]) {
                  temp = partition_list[i];
                  partition_list[i] = partition_list[j];
                  partition_list[j] = temp;
              }
          }
      }
      
      # Print header
      header = sprintf("%-20s %4s %4s", "User", "Jobs", "GPUs");
      separator = sprintf("%-20s %4s %4s", "----", "----", "----");
      for (i = 1; i <= n_partitions; i++) {
          header = header sprintf(" %15s", partition_list[i]);
          separator = separator sprintf(" %15s", "---------------");
      }
      print header;
      print separator;
      
      # Store user data for sorting
      n_users = 0;
      for (user in user_jobs) {
          user_list[++n_users] = user;
      }
      
      # Sort users by GPU count (descending)
      for (i = 1; i <= n_users; i++) {
          for (j = i + 1; j <= n_users; j++) {
              if (user_gpus[user_list[i]] < user_gpus[user_list[j]]) {
                  temp = user_list[i];
                  user_list[i] = user_list[j];
                  user_list[j] = temp;
              }
          }
      }
      
      # Print sorted user data
      for (i = 1; i <= n_users; i++) {
          user = user_list[i];
          line = sprintf("%-20s %4d %4d", user, user_jobs[user], user_gpus[user]+0);
          for (j = 1; j <= n_partitions; j++) {
              p = partition_list[j];
              p_jobs = user_partition_jobs[user,p] + 0;
              p_gpus = user_partition_gpus[user,p] + 0;
              if (p_jobs > 0 || p_gpus > 0) {
                  line = line sprintf(" %15s", p_jobs " jobs, " p_gpus " gpus");
              } else {
                  line = line sprintf(" %15s", "");
              }
          }
          print line;
      }
  }'
}

function gpu_alloc {
  if ! command -v sinfo >/dev/null 2>&1 || ! command -v scontrol >/dev/null 2>&1; then
    echo "SLURM not found: require sinfo and scontrol" >&2
    return 1
  fi

  local FILTER_PART=""
  local FILTER_NODE=""
  local OPTIND opt
  OPTIND=1
  while getopts ":p:n:" opt; do
    case "$opt" in
      p) FILTER_PART="$OPTARG" ;;
      n) FILTER_NODE="$OPTARG" ;;
      :) echo "Error: option -$OPTARG requires an argument" >&2; return 1 ;;
      \?) echo "Usage: gpu_alloc [-p partition] [-n node_substring]" >&2; return 1 ;;
    esac
  done
  shift $((OPTIND-1))
  if [ $# -gt 0 ]; then
    echo "Usage: gpu_alloc [-p partition] [-n node_substring]" >&2
    return 1
  fi

  local -a PART_OPT
  if [[ -n "$FILTER_PART" ]]; then PART_OPT=(-p "$FILTER_PART"); else PART_OPT=(); fi

  local rows
  rows=$(
    sinfo -h -N "${PART_OPT[@]}" -o "%N" | sort -u | while IFS= read -r node; do
      line=$(scontrol show node -o "$node" 2>/dev/null)
      cfg=$(printf "%s\n" "$line" | awk 'match($0,/CfgTRES=([^ ]+)/,m){print m[1]}')
      alloc=$(printf "%s\n" "$line" | awk 'match($0,/AllocTRES=([^ ]+)/,m){print m[1]}')
      parts=$(printf "%s\n" "$line" | awk 'match($0,/Partitions=([^ ]+)/,m){print m[1]}')
      [ -z "$parts" ] && parts="-"
      if [[ -n "$FILTER_PART" ]]; then
        case ",$parts," in
          *,${FILTER_PART},*) ;;
          *) continue ;;
        esac
      fi
      if [[ -n "$FILTER_NODE" && "$node" != *"$FILTER_NODE"* ]]; then
        continue
      fi
      state_raw=$(printf "%s\n" "$line" | awk 'match($0,/State=([^ ]+)/,m){print m[1]}')
      state_base=${state_raw%%[*+() ,]*}
      state=$(printf "%s" "${state_base:-}" | tr '[:upper:]' '[:lower:]')
      [ -z "$state" ] && state="-"
      total=$(awk -v tres="$cfg" 'BEGIN{n=split(tres,a,",");s=0;for(i=1;i<=n;i++){split(a[i],kv,"=");k=kv[1];v=kv[2];if(k ~ /^gres\/gpu(:|$)/){gsub(/[^0-9]/,"",v); if(v!="") s+=v+0;}}; print s+0}')
      used=$(awk -v tres="$alloc" 'BEGIN{n=split(tres,a,",");s=0;for(i=1;i<=n;i++){split(a[i],kv,"=");k=kv[1];v=kv[2];if(k ~ /^gres\/gpu(:|$)/){gsub(/[^0-9]/,"",v); if(v!="") s+=v+0;}}; print s+0}')
      printf "%s\t%s\t%s/%s\t%s\n" "$node" "$parts" "$used" "$total" "$state"
    done
  )

  {
    printf "node\tpartition\tgpu: alloc/total\tstatus\n"
    printf "%s\n" "$rows"
  } | awk '
    BEGIN { FS = "\t"; sep = "   " }
    {
      lines[NR] = $0
      if (NF > nfields) nfields = NF
      for (i = 1; i <= NF; i++) {
        field_len = length($i)
        if (field_len > maxw[i]) maxw[i] = field_len
      }
    }
    END {
      split(lines[1], h, FS)
      for (i = 1; i <= nfields; i++) {
        printf "%-" maxw[i] "s", h[i]
        if (i < nfields) printf "%s", sep
      }
      printf "\n"

      for (i = 1; i <= nfields; i++) {
        for (j = 0; j < maxw[i]; j++) printf "-"
        if (i < nfields) printf "%s", sep
      }
      printf "\n"

      for (r = 2; r <= NR; r++) {
        split(lines[r], f, FS)
        for (i = 1; i <= nfields; i++) {
          printf "%-" maxw[i] "s", f[i]
          if (i < nfields) printf "%s", sep
        }
        printf "\n"
      }
    }'
}

function gpu_free {
  if ! command -v sinfo >/dev/null 2>&1 || ! command -v scontrol >/dev/null 2>&1; then
    echo "SLURM not found: require sinfo and scontrol" >&2
    return 1
  fi

  local rows
  rows=$(
    sinfo -N -h -o "%N %P" | while read -r node part; do
      part="${part%\*}"
      line=$(scontrol show node -o "$node" 2>/dev/null)
      cfg=$(printf "%s\n" "$line" | awk 'match($0,/CfgTRES=([^ ]+)/,m){print m[1]}')
      alloc=$(printf "%s\n" "$line" | awk 'match($0,/AllocTRES=([^ ]+)/,m){print m[1]}')
      total=$(awk -v tres="$cfg" 'BEGIN{n=split(tres,a,",");s=0;for(i=1;i<=n;i++){split(a[i],kv,"=");k=kv[1];v=kv[2];if(k ~ /^gres\/gpu(:|$)/){gsub(/[^0-9]/,"",v); if(v!="") s+=v+0;}}; print s+0}')
      used=$(awk -v tres="$alloc" 'BEGIN{n=split(tres,a,",");s=0;for(i=1;i<=n;i++){split(a[i],kv,"=");k=kv[1];v=kv[2];if(k ~ /^gres\/gpu(:|$)/){gsub(/[^0-9]/,"",v); if(v!="") s+=v+0;}}; print s+0}')
      printf "%s\t%s\t%s\n" "$part" "$total" "$used"
    done
  )

  {
    printf "partition\ttotal\tallocated\tavailable\n"
    printf "%s\n" "$rows" | awk -F'\t' '
      {
        total[$1] += $2
        alloc[$1] += $3
      }
      END {
        n = asorti(total, sorted)
        for (i = 1; i <= n; i++) {
          p = sorted[i]
          avail = total[p] - alloc[p]
          printf "%s\t%d\t%d\t%d\n", p, total[p], alloc[p], avail
        }
      }'
  } | awk '
    BEGIN { FS = "\t"; sep = "   " }
    {
      lines[NR] = $0
      if (NF > nfields) nfields = NF
      for (i = 1; i <= NF; i++) {
        field_len = length($i)
        if (field_len > maxw[i]) maxw[i] = field_len
      }
    }
    END {
      split(lines[1], h, FS)
      for (i = 1; i <= nfields; i++) {
        printf "%-" maxw[i] "s", h[i]
        if (i < nfields) printf "%s", sep
      }
      printf "\n"

      for (i = 1; i <= nfields; i++) {
        for (j = 0; j < maxw[i]; j++) printf "-"
        if (i < nfields) printf "%s", sep
      }
      printf "\n"

      for (r = 2; r <= NR; r++) {
        split(lines[r], f, FS)
        for (i = 1; i <= nfields; i++) {
          printf "%-" maxw[i] "s", f[i]
          if (i < nfields) printf "%s", sep
        }
        printf "\n"
      }
    }'
}

function git_cleanup {
  if ! git rev-parse --is-inside-work-tree &>/dev/null; then
    echo "error: not a git repository" >&2
    return 1
  fi

  # auto-detect base branch
  local base
  if git show-ref --verify --quiet refs/heads/main; then
    base="main"
  elif git show-ref --verify --quiet refs/heads/master; then
    base="master"
  else
    echo "error: neither 'main' nor 'master' branch found" >&2
    return 1
  fi

  local current
  current="$(git symbolic-ref --short HEAD 2>/dev/null)"

  echo "Base branch: $base"
  echo "Fetching and pruning remote tracking refs..."
  git fetch --prune

  # delete local branches already merged into base
  local merged_deleted=0
  while IFS= read -r branch; do
    branch="$(echo "$branch" | xargs)"
    [ -z "$branch" ] && continue
    [ "$branch" = "main" ] || [ "$branch" = "master" ] || [ "$branch" = "$current" ] && continue
    echo "Deleting merged branch: $branch"
    git branch -d "$branch"
    merged_deleted=$((merged_deleted + 1))
  done < <(git branch --merged "$base" --format='%(refname:short)')

  # find branches whose upstream is gone
  local gone_branches=()
  while IFS= read -r line; do
    local branch_name
    branch_name="$(echo "$line" | awk '{print $1}')"
    [ -z "$branch_name" ] && continue
    [ "$branch_name" = "main" ] || [ "$branch_name" = "master" ] || [ "$branch_name" = "$current" ] && continue
    gone_branches+=("$branch_name")
  done < <(git branch -vv | grep ': gone]')

  local gone_deleted=0
  if [ ${#gone_branches[@]} -gt 0 ]; then
    echo ""
    echo "Branches with deleted upstream:"
    printf "  %s\n" "${gone_branches[@]}"
    printf "Force-delete these branches? [y/N] "
    read -r confirm
    if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
      for branch in "${gone_branches[@]}"; do
        echo "Deleting gone branch: $branch"
        git branch -D "$branch"
        gone_deleted=$((gone_deleted + 1))
      done
    else
      echo "Skipped."
    fi
  fi

  echo ""
  echo "Done. Deleted $merged_deleted merged and $gone_deleted gone branch(es)."
}

# Regenerate the `ollama` provider block in pi's models.json from whatever
# ollama currently serves. pi has no ollama discovery -- every local model must
# be declared by hand -- so this runs after every `ollama pull`. It never
# touches defaultModel or web-search.json's summaryModel. See docs/ai-tools.md,
# "Local models via ollama".
function pi_sync_models {
  local models_json="$HOME/.pi/agent/models.json"
  local base="${OLLAMA_API_BASE:-http://127.0.0.1:11434}"

  command -v jq >/dev/null 2>&1 || { echo "pi_sync_models: jq not found" >&2; return 1; }
  [ -f "$models_json" ] || { echo "pi_sync_models: $models_json missing -- run 'stow .' in the dotfiles repo" >&2; return 1; }

  local names
  names="$(curl -sf -m 5 "$base/api/tags" | jq -r '.models[].name')" \
    || { echo "pi_sync_models: no ollama server at $base" >&2; return 1; }
  [ -n "$names" ] || { echo "pi_sync_models: ollama has no models installed" >&2; return 1; }

  # Ollama silently truncates anything past OLLAMA_CONTEXT_LENGTH, so declaring
  # a model's native window in models.json would just drop the head of the
  # conversation without a word. Cap at what the server will really allocate.
  local cap="${OLLAMA_CONTEXT_LENGTH:-4096}"

  local entries='[]' name info ctx window max_tokens sampling
  while IFS= read -r name; do
    [ -n "$name" ] || continue
    info="$(curl -sf -m 20 "$base/api/show" -d "$(jq -nc --arg m "$name" '{model:$m}')")" || {
      echo "pi_sync_models: skipping $name (show failed)" >&2
      continue
    }

    # Context length is keyed by architecture, e.g. "qwen3.context_length".
    ctx="$(printf '%s' "$info" | jq -r '
      [.model_info // {} | to_entries[] | select(.key | endswith(".context_length")) | .value] | first // empty')"
    [ -n "$ctx" ] || ctx="$cap"
    window=$(( ctx < cap ? ctx : cap ))
    max_tokens=$(( window / 4 ))
    [ "$max_tokens" -lt 1024 ] && max_tokens=1024

    # Gemma 4's family-wide best practice is temperature=1.0, top_p=0.95,
    # top_k=64 (ollama.com/library/gemma4). Pin it here so the generated entry
    # stays correct even if a model's baked-in defaults drift.
    sampling='null'
    case "$name" in
      gemma4:*) sampling='{"temperature":1.0,"top_p":0.95,"top_k":64}' ;;
    esac

    entries="$(printf '%s' "$info" | jq -c \
      --argjson acc "$entries" \
      --arg id "$name" \
      --argjson window "$window" \
      --argjson maxTokens "$max_tokens" \
      --argjson samplingParams "$sampling" '
      $acc + [({
        id: $id,
        name: ($id + " (" + (.details.parameter_size // "?") + " " + (.details.quantization_level // "?") + ", local)"),
        reasoning: (((.capabilities // []) | index("thinking")) != null),
        input: (if ((.capabilities // []) | index("vision")) != null then ["text", "image"] else ["text"] end),
        contextWindow: $window,
        maxTokens: $maxTokens,
        cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 }
      } + (if $samplingParams != null then { samplingParams: $samplingParams } else {} end))]')"
  done <<< "$names"

  # `cat >` writes through the stow symlink; `mv` would replace it with a
  # regular file and detach the deployed config from the repo.
  local tmp
  tmp="$(mktemp)" || return 1
  jq --argjson models "$entries" '.providers.ollama.models = $models' "$models_json" > "$tmp" \
    && cat "$tmp" > "$models_json"
  rm -f "$tmp"

  printf '%s' "$entries" | jq -r '.[] | "  " + .id + "  " + (.contextWindow | tostring) + " ctx"'
  echo "pi_sync_models: wrote $(printf '%s' "$entries" | jq 'length') model(s) to $models_json"
}
