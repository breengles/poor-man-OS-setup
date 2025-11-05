if [[ $(hostname) == "lambda-loginnode"* ]]; then
    emulate sh -c "source /etc/profile"
    module load slurm
    module load cuda12.4/toolkit/12.4.1
fi
