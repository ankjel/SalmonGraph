#!/bin/bash
#SBATCH --ntasks=1
#SBATCH --nodes=1
#SBATCH --mem=1G
#SBATCH --partition=smallmem
#SBATCH --job-name=pggb-main-param
#SBATCH --output=logs/log-main-param-%j-%a.out


filename="$SLURM_JOBID"_params.txt

for param in 2000 20000 100000
do 
    echo $param >> "$filename"
    
done


sbatch param_array.sh "G" "$filename"
