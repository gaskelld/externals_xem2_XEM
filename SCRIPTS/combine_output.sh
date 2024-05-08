#!/bin/tcsh
set targ=$1
set targ = {$1}
set min_angle=15.0
cd ../OUT/
cat header.txt >! xem2_emc_rc_$targ.out
@ i=1
while ($i <= 131)
    set angle=`echo "$min_angle+$i*0.2-0.2" | bc` 
    set angle_name=`echo "$angle" | tr '.' 'p'`
    set outfile1 = "${angle_name}_${targ}_part1.out"
    set outfile2 = "${angle_name}_${targ}_part2.out"
    cat $outfile1 $outfile2 >! temp.out
    cat temp.out >> xem2_emc_rc_$targ.out
    @ i++
end


