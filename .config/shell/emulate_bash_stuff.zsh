# if running from bash as login shell on remote cluster - uncomment the following lines
if [[ $(hostname) == "lambda-loginnode"* ]]; then
    emulate sh -c "source /etc/profile"
    module load slurm
fi
