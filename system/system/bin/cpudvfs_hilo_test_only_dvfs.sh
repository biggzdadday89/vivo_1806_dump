#!/system/bin/sh

ntest=3000000
delay=0.3	## 300ms

LL_ncpu=4
L_ncpu=4
B_ncpu=2

LL_ropp=0
L_ropp=0

LL_rcpu=4
L_rcpu=4

check=0

## keep screen always on
setprop persist.keep.awake true

for i in $(seq 1 ${ntest})
do
	echo "loop ${i}:"
	
	echo ${LL_rcpu} ${L_rcpu} > /proc/ppm/policy/ut_fix_core_num
	
	check=$(($RANDOM%2))
	
	if [ $check -eq 0 ]; then
		LL_ropp=0
		L_ropp=0
	else
		L_ropp=15
		LL_ropp=15
	fi

	echo ${LL_ropp} ${L_ropp} > /proc/ppm/policy/ut_fix_freq_idx
	echo "cpu=${LL_rcpu} ${L_rcpu}, opp=${LL_ropp} ${L_ropp}"

	sleep ${delay}

done

setprop persist.keep.awake false

echo "The test is done and PASS if no exception occurred."
