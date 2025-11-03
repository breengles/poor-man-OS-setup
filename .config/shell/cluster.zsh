if [[ $(hostname) == "lambda-loginnode"* ]]; then
    emulate sh -c "source /etc/profile"
    module load slurm
    module load cuda12.4/toolkit/12.4.1
    export HF_HOME="/weka/teams/gte/huggingface/hub"
    export HF_HUB_CACHE="$HF_HOME"
fi
