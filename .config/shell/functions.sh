#!/usr/bin/env bash

function calcimages {
  find "$1" -type f \( -name \*.jpg -o -name \*.jpeg -o -name \*.png \) | wc -l
}

function calcjson {
  find "$1" -type f -name "*.json" | wc -l
}

function update {
  if [ -x "$(command -v zinit)" ]; then
    echo "========== updating zinit =========="
    zinit self-update
    zinit update --all --parallel
    echo
  fi

  if [ -x "$(command -v brew)" ]; then
    echo "========== updating brew packages =========="
    brew update && brew upgrade
    echo
    echo "The following packages were NOT upgraded (PINNED):"
    brew list --pinned
    echo
  fi

  if [[ $(hostname) != *"login"* ]]; then
    if [ -x "$(command -v apt)" ]; then
      echo "========== updating apt packages =========="
      sudo apt update && sudo apt upgrade
      echo
    fi
  fi

  if [ -x "$(command -v cargo)" ]; then
    echo "========== updating cargo =========="
    cargo install-update --all --jobs 8
    echo
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
function q {
  sinfo
  echo ""
  squeue --user="$(whoami)" --format="%.16i %.16P %45j %.3T %.12M %18N"
  echo ""
  squeue --user="$(whoami)" --array --noheader -o '%T' | awk '{ 
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
}

function qq {
  watch -n 1 "squeue --user=\$(whoami) --array --noheader -o '%T' | awk '{ 
    total++; 
    counts[\$1]++; 
  } END { 
    running = counts[\"RUNNING\"] + 0;
    pending = counts[\"PENDING\"] + 0; 
    completing = counts[\"COMPLETING\"] + 0;
    other = total - running - pending - completing;
    printf \"Jobs: %d R=%d P=%d C=%d\", total, running, pending, completing;
    if (other > 0) printf \" O=%d\", other;
    printf \"\\n\";
  }'; echo ''; squeue --user=\$(whoami) --format='%.16i %.16P %45j %.3T %.12M %18N'"
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
  ssh "lambda-scalar0$1" -t "$(which nvitop)"
}

function gpu_usage {
  # Get basic job info and detailed GPU allocation info
  squeue -t RUNNING -h -o "%i %u %b %P %D %C" | while read jobid user gres partition nodes cpus; do
    echo "$jobid $user $gres $partition $nodes $cpus"
  done | awk '{
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
      \?) echo "Usage: all_gpu [-p partition] [-n node_substring]" >&2; return 1 ;;
    esac
  done
  shift $((OPTIND-1))
  if [ $# -gt 0 ]; then
    echo "Usage: all_gpu [-p partition] [-n node_substring]" >&2
    return 1
  fi

  local PART_OPT=""
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
