if [[ $(hostname) == "lambda-loginnode"* ]]; then
    emulate sh -c "source /etc/profile"
    module load slurm
fi
