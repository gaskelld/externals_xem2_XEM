#!/bin/tcsh
set targ=$1
set targ = {$1}

make_xem2_input_files.sh $targ
make_xem2_scripts.sh $targ

cd ../hcswif/FARM_SCRIPTS
readlink -f *_${targ}*.sh >! ${targ}_list.txt

cd ..

hcswif.py --mode command --command file /u/group/c-xem2/gaskelld/GIT/externals_xem2_XEM/hcswif/FARM_SCRIPTS/${targ}_list.txt --name externals_${targ} --account hallc --time 172800 --ram 50000000

swif2 import -file json/externals_${targ}.json
swif2 run externals_${targ}
