# Custom completion function for scancel command
_scancel_completion() {
    local -a job_ids
    local -a job_info
    
    # Get job IDs and basic info from squeue for current user only
    if command -v squeue >/dev/null 2>&1; then
        # Get job IDs with format: JOBID USER STATE NAME (filtered to current user)
        local squeue_output
        squeue_output=$(squeue -h -u "$USER" -o "%i %u %t %j" 2>/dev/null)
        
        if [[ -n "$squeue_output" ]]; then
            while IFS= read -r line; do
                local jobid=$(echo "$line" | awk '{print $1}')
                local user=$(echo "$line" | awk '{print $2}')
                local state=$(echo "$line" | awk '{print $3}')
                local name=$(echo "$line" | awk '{print $4}')
                
                # Add job ID with description
                job_ids+=("$jobid")
                job_info+=("$jobid:[$user] $state - $name")
            done <<< "$squeue_output"
        fi
    fi
    
    if (( ${#job_ids[@]} > 0 )); then
        _describe 'job IDs' job_info
    else
        _message "No jobs found"
    fi
}

# Custom completion function for srun command
_srun_completion() {
    local context state line
    typeset -A opt_args
    
    local -a partitions
    local -a nodes
    
    # Get available partitions
    if command -v sinfo >/dev/null 2>&1; then
        local sinfo_partitions
        sinfo_partitions=$(sinfo -h -o "%P" 2>/dev/null | sed 's/\*$//' | sort -u)
        if [[ -n "$sinfo_partitions" ]]; then
            while IFS= read -r partition; do
                partitions+=("$partition")
            done <<< "$sinfo_partitions"
        fi
    fi
    
    # Get available nodes
    if command -v sinfo >/dev/null 2>&1; then
        local sinfo_nodes
        sinfo_nodes=$(sinfo -h -o "%N" 2>/dev/null | sort -u)
        if [[ -n "$sinfo_nodes" ]]; then
            while IFS= read -r node; do
                nodes+=("$node")
            done <<< "$sinfo_nodes"
        fi
    fi
    
    _arguments -C \
        '--partition=[specify partition]:partition:($partitions)' \
        '-p[specify partition]:partition:($partitions)' \
        '--nodelist=[specify nodes]:nodes:($nodes)' \
        '-w[specify nodes]:nodes:($nodes)' \
        '--exclude=[exclude nodes]:nodes:($nodes)' \
        '-x[exclude nodes]:nodes:($nodes)' \
        '--nodes=[number of nodes]:nodes:' \
        '-N[number of nodes]:nodes:' \
        '--ntasks=[number of tasks]:tasks:' \
        '-n[number of tasks]:tasks:' \
        '--ntasks-per-node=[tasks per node]:tasks:' \
        '--cpus-per-task=[CPUs per task]:cpus:' \
        '-c[CPUs per task]:cpus:' \
        '--mem=[memory per node]:memory:' \
        '--mem-per-cpu=[memory per CPU]:memory:' \
        '--time=[time limit]:time:' \
        '-t[time limit]:time:' \
        '--job-name=[job name]:name:' \
        '-J[job name]:name:' \
        '--output=[output file]:file:_files' \
        '-o[output file]:file:_files' \
        '--error=[error file]:file:_files' \
        '-e[error file]:file:_files' \
        '--chdir=[working directory]:directory:_directories' \
        '-D[working directory]:directory:_directories' \
        '--export=[environment variables]:variables:' \
        '--gres=[generic resources]:resources:' \
        '--qos=[quality of service]:qos:' \
        '--account=[account]:account:' \
        '-A[account]:account:' \
        '--dependency=[job dependencies]:dependency:' \
        '-d[job dependencies]:dependency:' \
        '--exclusive[exclusive node access]' \
        '--overcommit[allow overcommit]' \
        '--no-kill[do not kill on node failure]' \
        '--pty[allocate pseudo terminal]' \
        '--interactive[run interactively]' \
        '-I[run interactively]' \
        '--immediate[exit if resources not available]' \
        '--help[show help]' \
        '-h[show help]' \
        '--version[show version]' \
        '-V[show version]' \
        '*:command or script:_files'
}

# Custom completion function for sbatch command
_sbatch_completion() {
    local context state line
    typeset -A opt_args
    
    local -a partitions
    local -a nodes
    local -a mail_types
    
    # Mail types for --mail-type
    mail_types=(
        'NONE:no mail'
        'BEGIN:job begins'
        'END:job ends'
        'FAIL:job fails'
        'REQUEUE:job requeued'
        'ALL:all events'
        'TIME_LIMIT:time limit reached'
        'TIME_LIMIT_90:90% of time limit reached'
        'TIME_LIMIT_80:80% of time limit reached'
        'TIME_LIMIT_50:50% of time limit reached'
        'ARRAY_TASKS:array task events'
    )
    
    # Get available partitions
    if command -v sinfo >/dev/null 2>&1; then
        local sinfo_partitions
        sinfo_partitions=$(sinfo -h -o "%P" 2>/dev/null | sed 's/\*$//' | sort -u)
        if [[ -n "$sinfo_partitions" ]]; then
            while IFS= read -r partition; do
                partitions+=("$partition")
            done <<< "$sinfo_partitions"
        fi
    fi
    
    # Get available nodes
    if command -v sinfo >/dev/null 2>&1; then
        local sinfo_nodes
        sinfo_nodes=$(sinfo -h -o "%N" 2>/dev/null | sort -u)
        if [[ -n "$sinfo_nodes" ]]; then
            while IFS= read -r node; do
                nodes+=("$node")
            done <<< "$sinfo_nodes"
        fi
    fi
    
    _arguments -C \
        '--partition=[specify partition]:partition:($partitions)' \
        '-p[specify partition]:partition:($partitions)' \
        '--nodelist=[specify nodes]:nodes:($nodes)' \
        '-w[specify nodes]:nodes:($nodes)' \
        '--exclude=[exclude nodes]:nodes:($nodes)' \
        '-x[exclude nodes]:nodes:($nodes)' \
        '--nodes=[number of nodes]:nodes:' \
        '-N[number of nodes]:nodes:' \
        '--ntasks=[number of tasks]:tasks:' \
        '-n[number of tasks]:tasks:' \
        '--ntasks-per-node=[tasks per node]:tasks:' \
        '--cpus-per-task=[CPUs per task]:cpus:' \
        '-c[CPUs per task]:cpus:' \
        '--mem=[memory per node]:memory:' \
        '--mem-per-cpu=[memory per CPU]:memory:' \
        '--time=[time limit]:time:' \
        '-t[time limit]:time:' \
        '--job-name=[job name]:name:' \
        '-J[job name]:name:' \
        '--output=[output file]:file:_files' \
        '-o[output file]:file:_files' \
        '--error=[error file]:file:_files' \
        '-e[error file]:file:_files' \
        '--input=[input file]:file:_files' \
        '-i[input file]:file:_files' \
        '--chdir=[working directory]:directory:_directories' \
        '-D[working directory]:directory:_directories' \
        '--export=[environment variables]:variables:' \
        '--gres=[generic resources]:resources:' \
        '--qos=[quality of service]:qos:' \
        '--account=[account]:account:' \
        '-A[account]:account:' \
        '--dependency=[job dependencies]:dependency:' \
        '-d[job dependencies]:dependency:' \
        '--array=[job array]:array:' \
        '-a[job array]:array:' \
        '--mail-type=[mail events]:mail_type:_describe "mail types" mail_types' \
        '--mail-user=[mail address]:email:' \
        '--begin=[start time]:time:' \
        '--deadline=[deadline]:time:' \
        '--licenses=[licenses]:licenses:' \
        '-L[licenses]:licenses:' \
        '--constraint=[node features]:constraint:' \
        '-C[node features]:constraint:' \
        '--tmp=[temporary disk space]:disk:' \
        '--exclusive[exclusive node access]' \
        '--overcommit[allow overcommit]' \
        '--no-kill[do not kill on node failure]' \
        '--no-requeue[do not requeue job]' \
        '--requeue[requeue job on failure]' \
        '--hold[submit job in hold state]' \
        '-H[submit job in hold state]' \
        '--parsable[return job ID in parsable format]' \
        '--test-only[validate job script]' \
        '--wrap=[wrap command]:command:' \
        '--get-user-env[get user environment]' \
        '--export-file=[export environment file]:file:_files' \
        '--verbose[verbose output]' \
        '-v[verbose output]' \
        '--help[show help]' \
        '-h[show help]' \
        '--version[show version]' \
        '-V[show version]' \
        '*:batch script:_files -g "*.sh *.slurm *.sbatch"'
}

# Register the completion functions
compdef _scancel_completion scancel
compdef _srun_completion srun
compdef _sbatch_completion sbatch
