#!/bin/csh
# creat input files for a give target
# 
# 
set targ = {$1}
set min_angle=3.0
cd ../INP/
# Loop over angles
@ i=1
while ($i <= 51)
    set angle=`echo "$min_angle+$i*0.2-0.2" | bc` 
#    echo $angle
    set angle_name=`echo "$angle" | tr '.' 'p'`
    set infile = "${angle_name}_${targ}_src_part1.inp"
    echo $infile
    sed -e "s/<angle>/$angle/;s/<targ>/$targ/" < src_inp_part1.template >! $infile
    set infile = "${angle_name}_${targ}_src_part2.inp"
    echo $infile
    sed -e "s/<angle>/$angle/;s/<targ>/$targ/" < src_inp_part2.template >! $infile
    @ i++
end
