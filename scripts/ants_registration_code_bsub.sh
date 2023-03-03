#BSUB -n 8
bsub -o /project/msdepression/scripts/logfiles/outputlogjob_ants_registration_code.out -e /project/msdepression/scripts/logfiles/outputlogjob_ants_registration_code.error -R "rusage[mem=128G]" < /project/msdepression/scripts/ants_registration_code.sh
