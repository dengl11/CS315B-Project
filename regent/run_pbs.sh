#!/bin/bash -l
#PBS -l nodes=1:ppn=24
#PBS -l walltime=00:50:00
#PBS -m abe
#PBS -q gpu
#PBS -d .

LAUNCHER='mpirun --bind-to none -np 1 -npernode 1' ~/legion/language/regent.py ~/CS315B-Project/regent/decision_tree_parallel_classifier.rg -train ~/CS315B-Project/data/adult/adult_train.tsv -test ~/CS315B-Project/data/adult/adult_test.tsv -lg:spy -logfile ~/CS315B-Project/regent/out/adult/seq.log -d 2 -p 4 -ll:cpu 8 -ll:csize 20480 -ll:dma 2


